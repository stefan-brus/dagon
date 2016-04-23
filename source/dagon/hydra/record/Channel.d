/**
 * Struct representing a slack channel
 */

module dagon.hydra.record.Channel;

import util.meta.ListSearch;

/**
 * Wrapper struct for a list of channels
 */

alias Channels = ListSearch!(Channel, "id", "name");

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
}
