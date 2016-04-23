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
     * The current message id
     */

    private ulong msg_id;

    /**
     * Constructor
     *
     * Params:
     *      token = The slack auth token
     */

    this ( string token )
    {
        this.token = token;
        this.msg_id = 1;

        enum PING_INTERVAL = 5;
        setTimer(PING_INTERVAL.seconds, &this.ping, true);
    }

    /**
     * Connect to the slack real time messaging API
     */

    void connect ( )
    {
        string ws_url;
        auto auth_url = "https://slack.com/api/rtm.start?token=" ~ this.token;

        // Get the websocket URL
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

        // Set up websocket connection
        this.ws = connectWebSocket(URL(ws_url));
        enforce(this.ws.connected, "Unable to establish websocket connection");
        logInfo("Websocket connection created");

        // Expect a hello message
        auto hello_msg = this.ws.receiveText();
        logInfo("Received message: %s", hello_msg);
        auto hello_json = parseJson(hello_msg);
        enforce(hello_json["type"].get!string == "hello", "Expected hello message");
    }

    /**
     * Handle slack events
     */

    void handleEvents ( )
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

    /**
     * Helper function to send a JSON message
     *
     * Handles incrementing of the current message ID and adds it to the JSON
     *
     * Params:
     *      json = The message JSON
     *
     * Returns:
     *      The response
     */

    private Json sendJson ( Json json )
    {
        json["id"] = this.msg_id;
        this.msg_id++;

        this.ws.send(json.toString());

        return parseJsonString(this.ws.receiveText());
    }

    /**
     * Timer delegate to send a ping message if the websocket is connected
     */

    private void ping ( )
    {
        logInfo("Pinging");
        auto ping_json = Json(["type": Json("ping")]);

        auto response = sendJson(ping_json);
        enforce(response["type"].get!string == "pong", "Ping was not ponged");
        logInfo("Ponged");
    }
}
