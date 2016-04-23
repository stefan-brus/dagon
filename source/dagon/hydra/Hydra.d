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
     * Get the user list and channel list after connecting
     */

    override protected void onConnect ( )
    {
        this.data.channels = this.getList!Channel("channels.list", "channels");
        logInfo("Channels: %s", this.data.channels.names());

        this.data.users = this.getList!User("users.list", "members");
        logInfo("Users: %s", this.data.users.names());
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

            if ( result !is null )
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
}
