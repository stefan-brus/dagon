/**
 * Slack connection handler
 */

module dagon.hydra.Slack;

import vibe.d;

import std.exception;

class Slack
{
    /**
     * The authorization URL
     */

    enum AUTH_URL = "https://slack.com/api/rtm.start";

    /**
     * The auth token
     */

    private string token;

    /**
     * The websocket
     */

    private WebSocket ws;

    /**
     * Constructor
     *
     * Params:
     *      token = The slack auth token
     */

    this ( string token )
    {
        this.token = token;
    }

    /**
     * Connect to the slack real time messaging API
     */

    public void connect ( )
    {
        string ws_url;
        auto auth_url = "https://slack.com/api/rtm.start?token=" ~ this.token;

        requestHTTP(auth_url,
            ( scope req )
            {

            },
            ( scope res )
            {
                auto json = res.readJson();
                enforce(json["ok"].get!bool, format("Error authenticating with slack: %s", json["error"].get!string));

                logInfo("Auth OK, websocket URL: %s", json["url"].get!string);
                ws_url = json["url"].get!string;
            }
        );

        this.ws = connectWebSocket(URL(ws_url));
        enforce(this.ws.connected, "Unable to establish websocket connection");
        logInfo("Websocket connection created");

        auto hello_msg = this.ws.receiveText();
        logInfo("Received message: %s", hello_msg);
        auto hello_json = parseJson(hello_msg);
        enforce(hello_json["type"].get!string == "hello", "Expected hello message");
    }

    /**
     * Handle slack events
     */

    public void handleEvents ( )
    in
    {
        assert(this.ws !is null && this.ws.connected);
    }
    body
    {
        while ( true )
        {
            try
            {
                auto event_msg = this.ws.receiveText();
                logInfo("Received event: %s", event_msg);
            }
            catch ( WebSocketException wse )
            {
                // Sometimes the connection breaks
                // In this case it needs to be re-established
                logInfo("Slack connection lost");
                this.connect();
                logInfo("Slack connection re-established");
                enforce(this.ws.connected, "Unable to re-establish Slack connection");
            }
        }
    }
}
