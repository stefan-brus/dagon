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

    import vibe.d;

    /**
     * The channel list
     */

    private Channels channels;

    /**
     * The user list
     */

    private Users users;

    /**
     * Constructor
     *
     * Params:
     *      token = The slack auth token
     */

    this ( string token )
    {
        super(token);
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
        this.channels = this.getList!Channel("channels.list", "channels");
        logInfo("Channels: %s", this.channels.names());

        this.users = this.getList!User("users.list", "members");
        logInfo("Users: %s", this.users.names());
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
        import std.algorithm;
        import std.format;
        import std.string;

        auto text = event["text"].get!string;
        auto splitted = text.split(' ');

        if ( splitted.length > 1 && splitted[0] == ":hydra" )
        {
            switch ( splitted[1] )
            {
                case "users":
                    this.replyWith(event, format("Users in this slack: %s", this.users.names()));
                    break;

                case "channels":
                    this.replyWith(event, format("Channels in this slack: %s", this.channels.names()));
                    break;

                default:
                    logInfo("Unknown command: %s", splitted[1]);
                    break;
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
