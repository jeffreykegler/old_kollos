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

I have come comments on it,
which I hope will be helpful.
Some of which I answer questions you pose
in the tutorial.

## How to implement Leo's algorithm efficiency

In Joop Leo's he describes a lazy implementation of his algorithm,
which as you suggest takes an Earley parser into a situation
where it could be adding Earley items to many Earley sets at once.
As you point out, this would have implications for the kind
of data structure you need to use.

Marpa's solution is easy -- add Leo items eagerly.
That way they only need to be added to the one Earley set.
Leo's lazy implementation is *not*, as you suggest,
quadratic in time,
but linear,
and
[his 1991 paper]
(http://www.sciencedirect.com/science/article/pii/030439759190180A)
shows this,
though that can be hard to see if you're not familiar with
the literature.
Leo's paper skips most of the details,
because it assumes that its readers were familiar with
the complexity proofs for Earley's original algorithm.
Math papers usually do not
repeat arguments available
in standard textbooks or
in papers familiar to the people who know the field.

In an eager implementation, whenever you might
eventually want a Leo item in an Earley set,
you add it.
Marpa once it finishes each Earley set,
creates an index to it,
and this phase is a great opportunity for
adding the Leo items --
they essentially come at no additional overhead.

An additional optimization is useful.
Leo's 1991 adds Leo items for all rules,
even those for symbols
which are never part
of a right recursion.
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

The Marpa algorithm allows the user to specify
semantics for empty rules and nullable and
nulling symbols,
and the fact that the parse engine is using
a rewritten grammar is invisible to the user.

## Is Leo's optimization worth it?

You pose this question at the end of your right recursion
tutorial, and I think it can be answered, "yes".
With Leo's optimization,
Earley's can be made linear for every unambiguous grammar
which is free of ummarked middle recursions.
(Writing a grammar with unmarked middle recursions which
is still unambiguous is not easy to do, but Leo's 1991
shows how to do it.)

The advantage here can be seen in another of your excellent
writeups -- [the one motivating Earley parsing]
(http://loup-vaillant.fr/tutorials/earley-parsing/what-and-why).
It allows much
stronger claims to be made for Earley parsing:
if an LALR parser like yacc or bison can parse it,
a Leo parser can parse it in linear time.
(Bison can also switch to GLR, but GLR is not linear.)
Beyond LALR, Leo's parser parses LR(1) grammars in linear time.
In fact, Leo's parser parses LR(k) grammars in linaer time
for every constant value of k.

It is genuinely difficult to write an unambiguous
grammar which is *not* linear for Leo's algorithm.
You're unlikely to do it without trying,
and it is easy to avoid doing it -- just
stay unambiguous,
and be careful about unmarked middle recursion.
(Actually ambiguous gramars are also linear,
as long as you keep the ambiguity bounded.)

This opens the way to new techniques.
For example, you can now do true "higher order languages" -- languages
which write languages.
This is more useful than it might sound -- for example,
you can specify a set of rules, with precedence and association,
as they do in textbooks and standards,
and automatically transform it into a language which you can
reasonably expect to be parsed in linear time.

## Working on one Earley set at at time

Not directly related to the questions about Leo parsing,
but very much useful for efficient implementation is another
change -- rearranging the Earley parse engine so that,
instead of working on two Earley sets at a time,
it works on only one.
It's possible to arrange things so that for each Earley set

* you first perform all scans;
* then all completions;
* then all predictions;
* and finally do post-processing, including eager computation of Earley items.

This ordering of operations for the parse engine has a large number
of pleasant side effects.
One is that it makes the parser left-eidetic --
once the operations as described above are done,
an Earley set is complete, so that
you know completely the state of the parse so far,
including all rules and symbols recognized,
and precisely what symbols are expected next.
You can also imitate the most-loved feature of recursive descent --
you can hand control over to the user for their custom hacks,
so that you get the best of syntax-driven parsing and
parsing by custom hackery.

Best,

Jeffrey Kegler


