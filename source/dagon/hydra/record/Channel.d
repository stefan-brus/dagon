/**
 * Struct representing a slack channel
 */

module dagon.hydra.record.Channel;

/**
 * Wrapper struct for a list of channels
 */

struct Channels
{
    /**
     * The array of channels
     */

    Channel[] channels;

    alias channels this;

    /**
     * Get the channel names
     */

    string[] names ( )
    {
        string[] result;

        foreach ( channel; this )
        {
            result ~= channel.name;
        }

        return result;
    }
}

/**
 * Channel struct
 */

struct Channel
{
    /**
     * The channel ID
     */

    string id;

    /**
     * The channel name
     */

    string name;

    /**
     * The creation timestamp
     */

    long created;

    /**
     * The channel creator
     */

    string creator;

    /**
     * Whether or not the channel is archived
     */

    bool is_archived;

    /**
     * Whether or not hydra is a member
     */

    bool is_member;

    /**
     * The number of members
     */

    uint num_members;

    /**
     * The channel topic and purpose
     */

    struct Topic
    {
        /**
         * The topic value
         */

        string value;

        /**
         * The topic creator
         */

        string creator;

        /**
         * The timestamp of when it was last set
         */

        long last_set;
    }

    Topic topic;

    Topic purpose;
}
