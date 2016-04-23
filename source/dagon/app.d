module app;

import dagon.hydra.Slack;

import vibe.d;

import std.stdio;

shared static this ( )
{
    setLogFormat(FileLogger.Format.threadTime, FileLogger.Format.threadTime);
    logInfo("Setting up slack websocket connection");
    auto token = File(".slacktoken").readln().chomp();
    auto slack = new Slack(token);
    slack.connect();

    auto settings = new HTTPServerSettings;
    settings.port = 666;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    listenHTTP(settings, &hello);

	logInfo("Listening for HTTP connections on 127.0.0.1:666");

    slack.handleEvents();
}

void hello ( HTTPServerRequest req, HTTPServerResponse res )
{
	res.writeBody("Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn");
}
