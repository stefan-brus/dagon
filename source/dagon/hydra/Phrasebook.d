/**
 * Phrasebook module, contains a map of user names to markov chains
 */

module dagon.hydra.Phrasebook;

/**
 * Phrasebook struct
 */

struct Phrasebook
{
    import markov;

    /**
     * The user to markov chains map
     */

    alias Chain = MarkovChain!string;

    alias MarkovMap = Chain[string];

    private MarkovMap markov_map;

    /**
     * Learn a new phrase
     *
     * Splits the given string and feeds it to the markov chain for
     * the given user
     *
     * Params:
     *      user = The user name
     *      phrase = The phrase string
     */

    void learn ( string user, string phrase )
    {
        import std.string;

        if ( !(user in this.markov_map) )
        {
            this.markov_map[user] = Chain(1, 2, 3);
        }

        this.markov_map[user].train(phrase.split(' '));
    }

    /**
     * Generate a phrase for the given user
     *
     * Returns null if the user does not have a markov chain
     *
     * Params:
     *      user = The user name
     *      len = The number of words in the phrase
     *
     * Returns:
     *      The generated phrase
     */

    string generate ( string user, uint len )
    {
        if ( !(user in this.markov_map) ) return null;

        this.markov_map[user].seed(this.markov_map[user].random());
        string result;

        foreach ( i; 0 .. len )
        {
            result ~= this.markov_map[user].generate();
            if ( i != len ) result ~= ' ';
        }

        return result;
    }
}
