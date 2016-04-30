
module state_machine.test.common;

import state_machine;

version(unittest)
{
    struct Order
    {
        mixin StateMachine!(status, "pending", "ordered", "paid");

    private:
        int status;

        double balance = 0;
        double total   = 0;

        @BeforeTransition("ordered")
        bool isPendingAndTotalNonZero()
        {
            return this.pending && total > 0;
        }

        @AfterTransition("ordered")
        void setBalanceFromTotal()
        {
            balance = total;
        }

        @BeforeTransition("paid")
        bool isOrderedAndBalanceZero()
        {
            return this.ordered && balance == 0;
        }
    }
}

static unittest
{
    Order o;

    static assert(is(typeof(o.statusNames()) == string[]));

    static assert(is(typeof(o.pending()) == bool));
    static assert(is(typeof(o.ordered()) == bool));
    static assert(is(typeof(o.paid()) == bool));

    static assert(is(typeof(o.toPending()) == bool));
    static assert(is(typeof(o.toOrdered()) == bool));
    static assert(is(typeof(o.toPaid()) == bool));
}

unittest
{
    Order o;

    assert(o.statusNames == ["pending", "ordered", "paid"]);

    assert(o.status == 0);
    assert(o.pending is true);
    assert(o.ordered is false);
    assert(o.paid is false);

    assert(o.total == 0);
    assert(o.toOrdered is false);
    assert(o.pending is true);

    o.total = 5000;
    assert(o.total == 5000);
    assert(o.toOrdered is true);
    assert(o.ordered is true);
    assert(o.pending is false);
    assert(o.balance == o.total);

    assert(o.balance != 0);
    assert(o.toPaid is false);
    assert(o.ordered is true);

    o.balance = 0;
    assert(o.balance == 0);
    assert(o.toPaid is true);
    assert(o.paid is true);
    assert(o.ordered is false);
}
