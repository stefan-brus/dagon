/**
 * Struct representing a slack user
 */

module dagon.hydra.record.User;

import util.meta.ListSearch;

/**
 * Wrapper struct for a list of users
 */

alias Users = ListSearch!(User, "name");

/**
 * User struct
 */

struct User
{
    /**
     * The user ID
     */

    string id;

    /**
     * The user name
     */

    string name;
}
