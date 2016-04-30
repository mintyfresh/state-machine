
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

version(unittest)
{
    enum UserStatus : string
    {
        none       = null,
        registered = "registered",
        confirmed  = "confirmed",
        banned     = "banned"
    }

    struct User
    {
        mixin StateMachine!status;

        UserStatus status;

        string email;
        bool confirmationSent;

        string password;
        string reason;

        @BeforeTransition("registered")
        bool isNewUserAndHasEmailAddress()
        {
            return this.none && email.length != 0;
        }

        @AfterTransition("registered")
        void sendEmailConfirmation()
        {
            // TODO : mailer.send("email_confirmation");
            confirmationSent = true;
        }

        @BeforeTransition("confirmed")
        bool isRegisteredAndSetPassword()
        {
            return this.registered && password.length >= 6;
        }

        @BeforeTransition("banned")
        bool isBanReasonGiven()
        {
            return reason.length != 0;
        }
    }
}

static unittest
{
    User u;

    static assert(is(typeof(u.statusNames()) == string[]));

    static assert(is(typeof(u.none()) == bool));
    static assert(is(typeof(u.registered()) == bool));
    static assert(is(typeof(u.confirmed()) == bool));
    static assert(is(typeof(u.banned()) == bool));

    static assert(is(typeof(u.toNone()) == bool));
    static assert(is(typeof(u.toRegistered()) == bool));
    static assert(is(typeof(u.toConfirmed()) == bool));
    static assert(is(typeof(u.toBanned()) == bool));
}

unittest
{
    User u;

    assert(u.status is null);
    assert(u.email is null);
    assert(u.password is null);
    assert(u.reason is null);
    assert(u.confirmationSent is false);

    assert(u.none is true);
    assert(u.registered is false);
    assert(u.confirmed is false);
    assert(u.banned is false);

    assert(u.toRegistered is false);
    assert(u.registered is false);
    assert(u.none is true);

    u.email = "webmaster@john.smith.com";
    assert(u.toRegistered is true);
    assert(u.registered is true);
    assert(u.none is false);
    assert(u.confirmationSent is true);

    assert(u.toConfirmed is false);
    assert(u.confirmed is false);
    assert(u.registered is true);

    u.password = "foo bar";
    assert(u.toConfirmed is true);
    assert(u.confirmed is true);
    assert(u.registered is false);

    assert(u.toBanned is false);
    assert(u.confirmed is true);
    assert(u.banned is false);

    u.reason = "Spam";
    assert(u.toBanned is true);
    assert(u.banned is true);
    assert(u.confirmed is false);
}
