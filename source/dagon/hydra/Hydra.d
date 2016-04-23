/**
 * Hydra the slack bot
 */

module dagon.hydra.Hydra;

import dagon.hydra.model.ISlack;
import dagon.hydra.record.Channel;

import vibe.d;

/**
 * Hydra class
 */

class Hydra : ISlack
{
    /**
     * The channel list
     */

    private Channels channels;

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
        this.getChannelList();
    }

    /**
     * Handle a message event
     *
     * Params:
     *      event = The event JSON
     */

    private void handleMessage ( Json event )
    {
        import std.algorithm;

        // Reply if someone said hydra
        if ( event["text"].get!string.canFind("hydra") )
        {
            this.replyWith(event, "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn");
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
     * Helper function to get the channel list
     */

    private void getChannelList ( )
    {
        this.channels.length = 0;

        auto channels_json = this.slackApi("channels.list")["channels"];

        foreach ( channel_json; channels_json )
        {
            this.channels ~= channel_json.deserializeJson!Channel();
        }

        logInfo("Channels: %s", this.channels.names());
    }
}
