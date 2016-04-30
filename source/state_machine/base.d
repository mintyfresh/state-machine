
module state_machine.base;

/// State machine using an integer or string state variable.
mixin template StateMachine(alias variable, states...)
    if((is(typeof(variable) : int) || is(typeof(variable) : string)) &&
       states.length > 0)
{
    import std.algorithm;
    import std.meta;
    import std.string;
    import std.traits;

    private
    {
        struct BeforeTransition
        {
            string state;
        }

        struct AfterTransition
        {
            string state;
        }
    }

    @property
    static string[] opDispatch(string op : variable.stringof ~ "Names")()
    {
        return [ states ];
    }

    @property
    bool opDispatch(string state)()
        if([ states ].countUntil(state) != -1)
    {
        enum index = [ states ].countUntil(state);

        // Compare state variable.
        static if(is(typeof(variable) : int))
        {
            return variable == index;
        }
        else
        {
            return variable == state;
        }
    }

    bool opDispatch(string state)()
        if(state.length > 2 && state[0 .. 2] == "to" &&
           [ states ].map!capitalize.countUntil(state[2 .. $]) != -1)
    {
        enum index = [ states ].map!capitalize.countUntil(state[2 .. $]);

        foreach(name; __traits(allMembers, typeof(this)))
        {
            alias member = Alias!(__traits(getMember, typeof(this), name));

            static if(is(typeof(member) == function))
            {
                static if(arity!member == 0)
                {
                    foreach(attribute; __traits(getAttributes, member))
                    {
                        static if(is(attribute == BeforeTransition) ||
                                 (is(typeof(attribute) == BeforeTransition) &&
                                  attribute.state == states[index]))
                        {
                            static if(is(typeof(member()) : bool))
                            {
                                if(!member())
                                {
                                    return false;
                                }
                            }
                            else
                            {
                                member();
                            }
                        }
                    }
                }
            }
        }

        // Update state variable.
        static if(is(typeof(variable) : int))
        {
            variable = index;
        }
        else
        {
            variable = state;
        }

        foreach(name; __traits(allMembers, typeof(this)))
        {
            alias member = Alias!(__traits(getMember, typeof(this), name));

            static if(is(typeof(member) == function))
            {
                static if(arity!member == 0)
                {
                    foreach(attribute; __traits(getAttributes, member))
                    {
                        static if(is(attribute == AfterTransition) ||
                                 (is(typeof(attribute) == AfterTransition) &&
                                  attribute.state == states[index]))
                        {
                            member();
                        }
                    }
                }
            }
        }

        return true;
    }
}
