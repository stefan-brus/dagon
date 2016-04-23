/**
 * Commands module
 */

module dagon.hydra.Commands;

/**
 * Commands class
 */

class Commands
{
    import dagon.hydra.Hydra;

    /**
     * Shared data reference
     */

    private Hydra.SharedData data;

    /**
     * Constructor
     *
     * Params:
     *      data = The shared data
     */

    this ( Hydra.SharedData data )
    {
        this.data = data;
    }

    /**
     * Execute a command
     *
     * Params:
     *      cmd = The command string
     *      args = The command arguments
     *
     * Returns:
     *      The command result
     */

    string run ( string cmd, string[] args )
    {
        import std.format;
        import std.random;

        switch ( cmd )
        {
            case "users":
                return format("Users in this slack: %s", this.data.users.names());

            case "channels":
                return format("Channels in this slack: %s", this.data.channels.names());

            case "imitate":
                if ( args.length == 1 )
                {
                    enum PHRASE_MAX_LEN = 20;
                    return this.data.phrasebook.generate(args[0], uniform(1, PHRASE_MAX_LEN + 1));
                }
                break;

            default:
                break;
        }

        return null;
    }
}
