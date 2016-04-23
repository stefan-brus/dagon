/**
 * Slack connection handler base class
 */

module dagon.hydra.model.ISlack;

abstract class ISlack
{
    import vibe.d;

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
        import std.exception;

        // Get the websocket URL
        auto auth_json = this.slackApi("rtm.start");
        enforce(auth_json["ok"].get!bool, format("Error authenticating with slack: %s", auth_json["error"].get!string));
        logInfo("Auth OK, websocket URL: %s", auth_json["url"].get!string);
        auto ws_url = auth_json["url"].get!string;

        // Set up websocket connection
        this.ws = connectWebSocket(URL(ws_url));
        enforce(this.ws.connected, "Unable to establish websocket connection");
        logInfo("Websocket connection created");

        // Expect a hello message
        auto hello_msg = this.ws.receiveText();
        logInfo("Received message: %s", hello_msg);
        auto hello_json = parseJson(hello_msg);
        enforce(hello_json["type"].get!string == "hello", "Expected hello message");

        this.onConnect();
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
        import std.exception;

        while ( true )
        {
            try
            {
                auto event_msg = this.ws.receiveText();
                logInfo("Received event: %s", event_msg);

                auto event_json = parseJson(event_msg);
                this.handleEvent(event_json);
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
     * Override this, handle a received event JSON
     *
     * Params:
     *      event = The event JSON
     */

    abstract protected void handleEvent ( Json event );

    /**
     * Override this, do something after connecting to slack
     */

    abstract protected void onConnect ( );

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

    protected Json sendJson ( Json json )
    {
        json["id"] = this.msg_id;
        this.msg_id++;

        this.ws.send(json.toString());

        return parseJsonString(this.ws.receiveText());
    }

    /**
     * Helper function to call the slack API
     *
     * Params:
     *      method = The method to call
     *
     * Returns:
     *      The Json response
     */

    protected Json slackApi ( string method )
    {
        import std.format;

        enum API_URL = "https://slack.com/api/";
        auto url = format("%s%s?token=%s", API_URL, method, this.token);

        Json json;
        logInfo("Calling API method %s", method);
        requestHTTP(url,
            ( scope req )
            {

            },
            ( scope res )
            {
                json = res.readJson();
                enforce(json["ok"].get!bool, "Error in API response");
                logInfo("%s received response: %s", method, json.toString());
            }
        );

        return json;
    }

    /**
     * Timer delegate to send a ping message if the websocket is connected
     */

    private void ping ( )
    {
        import std.exception;

        logInfo("Pinging");
        auto ping_json = Json(["type": Json("ping")]);

        auto response = sendJson(ping_json);
        enforce(response["type"].get!string == "pong", "Ping was not ponged");
        logInfo("Ponged");
    }
}
