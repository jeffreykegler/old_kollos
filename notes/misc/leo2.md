# Open letter to Loup Vaillant

Dear Loup,

Folks in the Marpa community
brought
[your write-up of Leo's algorithm]
(http://loup-vaillant.fr/tutorials/earley-parsing/right-recursion)
to my attention.
I am forced to report
that they found your description of Leo's algorithm
much clearer than mine.

I hope
you will find these comments helpful.
Some of them
answer questions that you pose
in the tutorial.

## How to implement Leo's algorithm efficiently

In Joop Leo's he describes a lazy implementation of his algorithm,
which as you suggest takes an Earley parser into a situation
where it could be adding Earley items to many Earley sets at once.
As you point out, this would have implications for the kind
of data structure you need to use.

Marpa's solution is easy -- add Leo items eagerly,
That way they only need to be added to the one Earley set
at a time.
Leo's lazy implementation is *not*, as you suggest,
quadratic in time,
but linear,
and
[his 1991 paper]
(http://www.sciencedirect.com/science/article/pii/030439759190180A)
shows this,
though how Leo shows this
can be hard to see if you're not familiar with
the literature.
Leo's paper skips most of the details,
and simply refers to Earley's complexity proofs.
Math papers usually do not
repeat arguments already available
in standard textbooks or
in papers familiar to the people who know the field.

In an eager implementation, whenever you might
eventually want a Leo item in an Earley set,
you add it.
Marpa,
once it finishes each Earley set,
creates an index to it by postdot symbol,
and this phase is a great opportunity for
adding the Leo items --
they essentially come at no additional overhead.

An additional optimization is useful.
Leo's 1991 adds Leo items for some rules
whose postdot symbols
which are never part
of a right recursion.
In the absence of a right recursion,
the payoff for a Leo item is always low --
it is bounded by a constant which depends on the grammar.
Marpa analyzes the grammar, and only adds
Leo items for right-recursive symbols.

## What about empty rules

You point out in your tutorial that empty rules
would introduce complications.
Aycock & Horspool came up with a clever way
of dealing with this -- rewrite the grammar.
Many grammar rewrites are impractical cheats,
because the rewritten grammar does not support
the same semantics as the original,
but this is not the case for Aycock & Horspool's
rewrite.

The Marpa algorithm uses a rewrite based
on the ideas of Aycock & Horspool,
and Marpa allows the user to specify
semantics for empty rules and nullable and
nulling symbols.
The fact that Marpa's parse engine is using
a rewritten grammar, free of empty rules,
is not visible to the user.

## Is Leo's optimization worth it?

You pose this question at the end of your right recursion
tutorial, and I think it can be answered, "yes".
The advantage here can be seen in another of your excellent
writeups -- [the one motivating Earley parsing]
(http://loup-vaillant.fr/tutorials/earley-parsing/what-and-why).
Leo's optimization would have allowed you to make much
stronger claims for Earley parsing:

+ If yacc or bison
    can parse a grammar in linear time,
    a Leo parser can parse it in linear time.

* Many grammars which
    yacc and bison cannot parse in linear time,
    a Leo parser can.

* With practice, it's straightforward, in practical cases,
    to determine if a grammar is linear for a Leo parser.
    Most users write Leo-linear grammars without thinking about it.
    A Leo parser is linear if a grammar

    + is free of ambiguous right recursions;

    + is free of unmarked middle recursions; and

    + is unambiguous, or has bounded ambiguity.

    None of these are things a grammar writer usually wants to do.

By contrast GLR is worst-case exponential, is non-linear for
many more grammars,
and requires the user to analyze the behavior of LR(1) states.

Because the Leo parser is linear for a vast class of grammars,
and is predictably so,
the way opens up to powerful new techniques.
For example, you can now do true "higher order languages" -- languages
which write languages.
This is more useful than it might sound -- for example,
you can specify a set of rules, with precedence and association,
as they do in textbooks and standards,
and programmatically transform it into a language which you can
reasonably expect to be parsed in linear time.
(Marpa::R2's DSL actually does this.)

## Working on one Earley set at at time

Not directly related to the questions about Leo parsing,
but very useful for efficient implementation,
is another
change -- rearranging the Earley parse engine so that,
instead of working on two Earley sets at a time,
it works on only one.
It's possible to arrange things so that for each Earley set

* you first perform all scans;
* then all completions;
* then all predictions;
* and finally do post-processing, including eager computation of Leo items.

This ordering of operations for the parse engine has a large number
of pleasant side effects.
One is that it makes the parser left-eidetic --
once the operations as described above are done,
an Earley set is complete, so that
you know completely the state of the parse so far,
including all rules and symbols recognized,
and precisely what symbols are expected next.
You can also duplicate the most-loved feature of recursive descent --
you can hand control over to the user for their custom hacks,
so that you get the best of syntax-driven parsing and
parsing by custom hackery.

Best,

Jeffrey Kegler

