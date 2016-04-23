/**
 * Template for a struct that wraps an array of an aggregate and provides
 * some methods of searching for properties of these aggregates
 */

module util.meta.ListSearch;

/**
 * List search template
 *
 * Template_params:
 *      T = The type of aggregate to wrap
 *      KeyField = The field to use as key for the index operator
 *      Fields = The fields to add lookups for
 */

struct ListSearch ( T, string KeyField, Fields ... )
{
    static assert(is(T == struct));

    /**
     * The array to wrap
     */

    T[] list;

    alias list this;

    mixin LookupMethods!(Fields);

    mixin(genOpIndex());

    /**
     * Helper template to generate the lookup methods
     *
     * Template_params:
     *      Fields = The fields to add lookups for
     */

    private template LookupMethods ( Fields ... )
    {
        static assert(Fields.length > 0);

        mixin LookupMethod!(Fields[0]);

        static if ( Fields.length > 1 )
        {
            mixin LookupMethods!(Fields[1 .. $]);
        }
    }

    /**
     * Helper template to generate a lookup method
     *
     * Template_params:
     *      Field = The field to add a lookup method for
     */

    private template LookupMethod ( string Field )
    {
        static assert(Field.length > 0);

        enum RetTypeStr = typeNameOfField!(Field);
        static assert(RetTypeStr.length > 0);

        mixin(RetTypeStr ~ "[] " ~ Field ~ `s ( )
{
    ` ~ RetTypeStr ~ `[] result;

    foreach ( elem; this )
    {
        result ~= elem.` ~ Field ~ `;
    }

    return result;
}`);
    }

    /**
     * Generate the opIndex method
     */

    private static string genOpIndex ( ) ( )
    {
        enum ParamTypeStr = typeNameOfField!(KeyField);
        return "T* opIndex ( " ~ ParamTypeStr ~ ` key )
{
    foreach ( ref elem; this )
    {
        if ( elem.` ~ KeyField ~ ` == key )
        {
            return &elem;
        }
    }

    return null;
}
`;
    }

    /**
     * Helper function to get the type name of a field in the aggregate
     *
     * Template_params:
     *      Field = The field to look up
     */

    private static string typeNameOfField ( string Field ) ( )
    {
        import std.traits;

        foreach ( i, FieldName; FieldNameTuple!T )
        {
            static if ( FieldName == Field )
            {
                return Fields!T[i].stringof;
            }
        }

        assert(false);
    }
}

unittest
{
    struct Entry
    {
        uint id;
        string text;
    }

    alias Entries = ListSearch!(Entry, "id");

    Entries entries;
    entries ~= Entry(42, "So long and thanks for all the fish");
    entries ~= Entry(666, "The bringer of light");

    assert(entries.ids == [42, 666]);
    assert(entries[42].text == "So long and thanks for all the fish");
    assert(entries[666].text == "The bringer of light");
}
