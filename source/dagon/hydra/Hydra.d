/**
 * Hydra the slack bot
 */

module dagon.hydra.Hydra;

import dagon.hydra.model.ISlack;

/**
 * Hydra class
 */

class Hydra : ISlack
{
    import dagon.hydra.record.Channel;
    import dagon.hydra.record.User;
    import dagon.hydra.Commands;
    import dagon.hydra.Phrasebook;

    import vibe.d;

    /**
     * The path to serialize the phrasebook to disk to
     */

    private enum PHRASEBOOK_PATH = "phrasebook.json";

    /**
     * Shared data aggregate
     */

    static class SharedData
    {
        /**
         * The channel list
         */

        Channels channels;

        /**
         * The user list
         */

        Users users;

        /**
         * The phrasebook
         */

        Phrasebook phrasebook;
    }

    private SharedData data;

    /**
     * The commands
     */

    private Commands commands;

    /**
     * Constructor
     *
     * Params:
     *      token = The slack auth token
     */

    this ( string token )
    {
        super(token);

        this.data = new SharedData();
        this.commands = new Commands(this.data);
    }

    /**
     * Handle a slack event
     *
     * Params:
     *      event = The event JSON
     */

    override protected void handleEvent ( Json event )
    {
        switch ( event["type"].get!string )
        {
            case "message":
                this.handleMessage(event);
                break;

            default:
                break;
        }
    }

    /**
     * Load necessary data after connecting
     */

    override protected void onConnect ( )
    {
        this.data.channels = this.getList!Channel("channels.list", "channels");
        logInfo("Channels: %s", this.data.channels.names());

        this.data.users = this.getList!User("users.list", "members");
        logInfo("Users: %s", this.data.users.names());

        if ( this.loadPhrasebook() ) logInfo("Phrasebook loaded from disk");
    }

    /**
     * Handle a message event
     *
     * Checks for command messages of the format ":hydra [COMMAND]"
     *
     * Params:
     *      event = The event JSON
     */

    private void handleMessage ( Json event )
    {
        import std.string;

        auto text = event["text"].get!string;
        auto splitted = text.split(' ');

        if ( splitted.length > 1 && splitted[0] == ":hydra" )
        {
            auto result = this.commands.run(splitted[1], splitted.length == 2 ? null : splitted[2 .. $]);

            if ( result.length > 0 )
            {
                this.replyWith(event, result);
            }
            else
            {
                logInfo("Unknown command: %s", splitted[1]);
            }
        }
        else
        {
            auto user = this.data.users[event["user"].get!string];

            if ( user !is null )
            {
                logInfo("Learning \"%s\" for user %s", text, user.name);
                this.data.phrasebook.learn(user.name, text);
                this.writePhrasebook();
                logInfo("Wrote phrasebook to disk");
            }
        }
    }

    /**
     * Helper function to reply to a message
     *
     * Params:
     *      event = The event JSON
     *      text = The reply text
     */

    private void replyWith( Json event, string text )
    {
        auto reply_json = Json(["type": Json("message"), "channel": event["channel"], "text": Json(text)]);

        logInfo("Replying to \"%s\" from %s with \"%s\"", event["text"].get!string, event["channel"].get!string, text);
        auto response = this.sendJson(reply_json);
        enforce(response["ok"].get!bool, "Unable to send reply");
    }

    /**
     * Helper function to get a list from the slack API
     *
     * Template_params:
     *      T = The aggregate type to get as a list
     *
     * Params:
     *      method = The API method
     *      list_key = The key to the JSON array
     */

    private T[] getList ( T ) ( string method, string list_key )
    {
        T[] result;

        auto json_arr = this.slackApi(method)[list_key];

        foreach ( json; json_arr )
        {
            result ~= json.deserializeJson!T();
        }

        return result;
    }

    /**
     * Load the phrasebook from disk, if it exists
     *
     * Returns:
     *      True if the phrasebook was loaded, false otherwise
     */

    private bool loadPhrasebook ( )
    {
        import markov.json.decoder;

        import std.file;

        this.data.phrasebook = Phrasebook.init;

        if ( exists(PHRASEBOOK_PATH) )
        {
            auto json = parseJsonString(readText(PHRASEBOOK_PATH));

            foreach ( ref string user, ref Json pb_json; json )
            {
                this.data.phrasebook[user] = decodeJSON!string(pb_json.toString());
            }
        }

        return false;
    }

    /**
     * Write the phrasebook to disk
     */

    private void writePhrasebook ( )
    {
        import markov.json.encoder;

        import std.file;

        auto json = Json.emptyObject;

        foreach ( user, chain; this.data.phrasebook )
        {
            json[user] = parseJsonString(encodeJSON!string(chain));
        }

        write(PHRASEBOOK_PATH, json.toString());
    }
}
