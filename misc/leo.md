# Implementing Joop Leo's Algorithm

Joop Leo's 1991 paper describes a modification to Earley's algorithm which
makes it linear for a vast class of grammars, one which includes all the
other grammar classes in practical use and then some.  Marpa implements
it, but others are interested in doing so as well -- and quite rightly so.
Leo's advance deserves far more attention than it has received.

Many of those who want to implement the Leo 1991 algorithm are math-averse
-- not necessarily hating math, but inclined to avoid a completely
mathematical and notation-intensive presentation of an algorithm, if
they can avoid it.  These notes are for them.

I am far from 100% sure these resources will be enough to do the job --
but a number of folks have expressed interest in them, so it's better
to put them out there and enable them to make the attempt.

+  In the Grune & Jacobs parsing textbook, it's discussed on pp.
224-226 of the 2nd edition.   There are mentions on pages 548 and 582.

+  My Marpa theory paper has pseudo-code for the algorithm.  Much of
the rest of the paper is math, but the pseudo-code should be readable
in isolaton.

+ You can run sample grammars in Marpa and see the Earley sets
    (with Leo items included) that it creates.  There are examples of this
    in the test suite in the files `t/leo_cycle.t` and `t/leo_example.t`.

    The call to show the sets is `show_earley_sets()` -- it is an
    undocumented internal call.  The Leo  items are the lines beginning
    with a capital letter 'L'


