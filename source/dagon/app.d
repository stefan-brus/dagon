module app;

import dagon.hydra.Hydra;

import vibe.d;

import std.stdio;

shared static this ( )
{
    setLogFormat(FileLogger.Format.threadTime, FileLogger.Format.threadTime);
    logInfo("Setting up slack websocket connection");
    auto token = File(".slacktoken").readln().chomp();
    auto hydra = new Hydra(token);
    hydra.connect();

    auto settings = new HTTPServerSettings;
    settings.port = 666;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    listenHTTP(settings, &hello);

	logInfo("Listening for HTTP connections on 127.0.0.1:666");

    hydra.handleEvents();
}

void hello ( HTTPServerRequest req, HTTPServerResponse res )
{
	res.writeBody("Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn");
}
