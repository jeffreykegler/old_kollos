# Strand parsing

This document describes Marpa's planned
"strand parsing" facility.
Strand parsing allows parsing to be done in pieces.
These pieces can then be "wound" together.

## Notation

Hyphenated names are very convenient in what follows,
while subtraction is rare.
In this document,
to avoid confusion,
subtraction will always be
shown as the addition of a negative.
For example `4+(-1) = 3`.

In the pseudo-code,
loops are often named.
The phrase `exit LOOP-X` means to not
execute any iterations of `LOOP-X`,
and not to execute any of the following
statements for the current iteration.

The phrase `continue LOOP-X` means to not
execute the any of the following statements for
the current iteration of the loop,
and instead to start
a new iteration of LOOP-X,
using the next item over which
the loop traverses.
At the end of the statements for any loop,
call it `LOOP-X`,
a `continue LOOP-X` is implied,
but it may also be stated explicitly
especially if the loop is long or
part of complex logic.

## Nucleobases and nucleotides

In an attempt to appeal to the intuition,
we employ terms that make
an analogy to DNA transcription and winding.
A DNA molecule consists of two "strands", which are joined
by "nucleobase pairs".
In DNA, there are four nucleobases: the familiar
cytosine (C), guanine (G), adenine (A) and thymine (T).
In our strand grammars, we will usually need many more
nucleobases.

For our purposes,
a *nucleobase* is a symbol
used to match part of a second symbol,
when that second symbol is
divided between two parses.
A *nucleotide* is a rule whose LHS
is a nucleobase.
A nucleotide may also have a nucleobase on its RHS.

## Grammars

The grammars considered here are Marpa internal
grammars.
Externally, Marpa handles arbitrary grammars,
which it rewrites into internal grammars which
observe a number of restrictions.
The restrictions that are relevant here are

* No cycles.

* No nulling grammars or zero-length parses.
  These are handled as special cases.

* No empty rules and no properly nullable symbols.
  These are eliminated using a rewrite suggested
  by Aycock and Horspool.

* No nulling symbols.  A non-nullable
  grammar parses exactly
  the same input strings with and without nulling symbols,
  so that nulling symbols can be eliminated before
  parsing and restored afterward.

The pseudo-code accessor `LHS(rule)`
returns the LHS symbol of a rule.

## Dotted rules

Dotted rules are of several kinds:

* predicted dotted rules, or *predictions*,
  in which the dot is before the first RHS symbol;

* completed dotted rules,
  or *completions*,
  in which the dot is after the last RHS symbol; and

* medial dotted rules,
  or *medials*,
  which are those dotted rules which are neither
  predictions or completions.

If `rule` is a rule, then

* `Prediction(rule)` is the dotted rule which is its prediction; and

* `Completion(rule)` is the dotted rule which is its completion.

If `dr` is a dotted rule, then

* `Rule(dr)` is its rule

A rule notion, when applied to a dotted rule,
is equivalent to that rule notion applied to the rule
of the dotted rule.
For example, a start dotted rule is a dotted rule
whose rule is a start rule.
Similarly, a pseudo-code accessor whose argument
can be a rule, when that argument is a
dotted rule, applies to the rule of the
dotted rule.
For example, if `dr` is a dotted rule,
```
     LHS(dr) == LHS(Rule(dr))
```

If a dotted rule is not a completion,
it will have a symbol after the dot,
called the *postdot symbol*.
The pseudo-code accessor `Postdot(dr)`
returns the postdot symbol of the dotted
rule `dr`.

## Location

At this point, the term *input location*
means the ordinal of an Earley set.
Unless otherwise specified,
the term *location* will refer to input locations.
When we introduce the concept of a bocage,
we will need to extend our definition of input
location but this definition suffices
until then.

## Earley items

As a reminder, an
Earley item, `yim`, consists of

* A dotted rule, `DR(yim)`.

* An origin, `Orig(yim)`, which is the location
  where `yim` starts.

* A current location, `Current(yim)`, which is
  the ordinal of Earley set
  that contains the Earley item `yim`,
  and which corresponds to the position of the
  dot in the RHS of the dotted rule.

Marpa creates links for its Earley items,
which track how and why they were created.
`Links(yim)` is the pseudo-code
accessor that returns the set of links
for the Earley item `yim`.

A dotted rule notion, when applied to a Earley item,
is equivalent to that dotted rule notion applied
to the dotted rule
of the Earley item.
For example, a medial Earley item is an Earley item
whose dotted rule is a medial.
Similarly, a pseudo-code accessor whose argument
can be a dotted rule, when that argument is a
Earley item, applies to the dotted rule of the
Earley item.
For example, if `yim` is an Earley item,
```
     Rule(yim) == Rule(DR(yim))
```

A rule notion, when applied to a Earley item,
is equivalent to that rule notion applied
to the rule of the dotted rule
of the Earley item.
For example, a start Earley item is an Earley item
in which the rule of the dotted rule is a start rule.
Similarly, a pseudo-code accessor whose argument
can be a rule, when that argument is a
Earley item, applies to the rule
of the dotted rule of the
Earley item.
For example, if `yim` is an Earley item,
```
     LHS(yim) == LHS(Rule(DR(yim)))
```

## The suffix grammar

Let our original grammar be `g-orig`.
We also call `g-orig` the pre-strand grammar.
We will need to extend `g-orig` to a
"suffix grammar".

We will call the original grammar,
before it has suffix rules and symbols added to it,
the "pre-strand grammar".
The rules of a pre-strand grammar are pre-strand rules
and the symbols of a pre-strand grammar are pre-strand symbols.

To extend the pre-strand grammar to a suffix grammar,
we will define,
a set of *nucleobase symbols*,
or *nucleobases*.
Nucleobase symbols exist to allow non-terminals to be split in half.
Nucleobases come in right and left versions.
For example, for the symbol `A`,
the nucleobases will be `A-L` and `A-R`.
The symbol `A` is called by *base symbol*
of the nucleobases `A-L` and `A-R`.

To extend the pre-strand grammar to a suffix grammar,
we also define pairs of 'nucleotide rules'.
In a pair of nucleotide rules,
one of the pair is 
a 'forward nucleotide' and
the other is
a 'reverse nucleotide'.

Let one of `g-orig`'s pre-strand rules be
```
     X ::= A B C
```
Call this rule `rule-X`.

The six pairs of
"nucleotide rules" that we will need for `rule-X` are
```
    1: X-L ::=                X-R ::= A B C
    2: X-L ::= A-L            X-R ::= A-R B C
    3: X-L ::= A              X-R ::= B C
    4: X-L ::= A B-L          X-R ::= B-R C
    5: X-L ::= A B            X-R ::= C
    6: X-L ::= A B C-L        X-R ::= C-R
```
`rule-X` is called the "base rule" of these nucleotides.
The pseudo-code accessor `Base-rule(rule)` returns the base
rule of a nucleotide rule.
If `rule` is not a nucleotide rule,
then
```
    Base-rule(rule) == rule
```

The base rule of a nucleotide must be unique.
When two different base rules might otherwise produce
the same nucleotide,
the nucleobase symbol names must be changed to prevent
this.
One way to do this is to,
when necessary,
encode
the base rule into
the nucleobase symbol name
with
a unique numeric identifier.

Each pair of nucleotides contains a forward
and a reverse nucleotide.
The forward nucleotide (shown as the left one
in the pairs above)
is so-called because it is intended
to be rejoined to a nucleotide to
its right,
which is the direction in which the parse proceeds
and which therefore can be called the "forward"
direction.
The reverse nucleotide is intended to be rejoined
with a forward nucleotide, which will be
"behind" it in the direction of parse,
or in the "reverse" of the direction in which
the parse proceeds.

Pairs 1, 3 and 5 are
"inter-nucleotides" --
nucleotides that split their base rule
at a point *between* two symbols.
Pairs 2, 4 and 6 are
"intra-nucleotides" --
nucleotides that split their base rule
at a point *within* a single symbol.

Every nucleotide has a "base dotted rule".
Dotted rules which are completions do not have nucleotides.
For each rule in the pre-strand parse,
every non-completion dotted rule,
call it `base-dr`,
has

* a forward inter-nucleotide,
  `Forward-Inter-Nucleotide(base-dr)`.

* a reverse inter-nucleotide,
  `Reverse-Inter-Nucleotide(base-dr)`,

* a forward intra-nucleotide,
  `Forward-Intra-Nucleotide(base-dr)`, and

* a reverse intra-nucleotide,
  `Reverse-Intra-Nucleotide(base-dr)`.

For the example above,

```
    Forward-inter-nucleotide([X ::= . A B C]) = [X-L ::= ]
    Reverse-inter-nucleotide([X ::= . A B C]) = [X-R ::= A B C]
    Forward-intra-nucleotide([X ::= . A B C]) = [X-L ::= A-L]
    Reverse-intra-nucleotide([X ::= . A B C]) = [X-R ::= A-R B C]
    Forward-inter-nucleotide([X ::= A . B C]) = [X-L ::= A]
    Reverse-inter-nucleotide([X ::= A . B C]) = [X-R ::= B C]
    Forward-intra-nucleotide([X ::= A . B C]) = [X-L ::= A B-L]
    Reverse-intra-nucleotide([X ::= A . B C]) = [X-R ::= B-R C]
    Forward-inter-nucleotide([X ::= A B . C]) = [X-L ::= A B]
    Reverse-inter-nucleotide([X ::= A B . C]) = [X-R ::= C]
    Forward-intra-nucleotide([X ::= A B . C]) = [X-L ::= A B C-L ]
    Reverse-intra-nucleotide([X ::= A B . C]) = [X-R ::= C-R]
```

We use the pseudo-code accessor `Nucleotide-match(rule)` to match
a nucleotide to the other nucleotide in its pair.
For every base dotted rule, `base-dr`
```
    Nucleotide-match(Forward-inter-nucleotide(base-dr))
         = Reverse-inter-nucleotide(base-dr)
    Nucleotide-match(Reverse-inter-nucleotide(base-dr))
         = Forward-inter-nucleotide(base-dr)
    Nucleotide-match(Forward-intra-nucleotide(base-dr))
         = Reverse-intra-nucleotide(base-dr)
    Nucleotide-match(Reverse-intra-nucleotide(base-dr))
         = Forward-intra-nucleotide(base-dr)
```
In all other cases, `Nucleotide-match(rule)` is undefined.

The inter-nucleotide pair whose base dotted rule has its dot
before the first RHS symbol is called the "prediction nucleotide pair".
In the above example,
the prediction nucleotides are pair 1, these two rules:
```
    X-L ::=
    X-R ::= A B C
```

The forward prediction nucleotide
of every pre-strand rule is nulling.
This rule is not used in parsing,
but it is used in the bocage nodes.
(The bocage structure is described [below](#BOCAGE).)
Marpa internal grammars do not allow nulling rules,
so 
this is one case where the grammar used in the
bocage nodes does not obey the restrictions
imposed on Marpa internal grammars.

## Converting dotted rules

In what follows, it will be necessary to change the rule
in dotted rules,

* from a nucleotide to its base rules,

* from a base rule to one of its nucleotides,

* between two nucleotides which share the same base rule.

In the process of converting a dotted rule
from one rule to another,
we will want to keep the dot position "stable".
This section explains how we do this.

Dotted rules are converted
using the `DR-convert()` pseudo-code function:

         to-dr = DR-convert(to-rule, from-dr)

where `to-dr`
is undefined unless
         
         Base-rule(to-rule) == Base-rule(from-dr)

Otherwise, `to-dr` is always such that

         Rule(to-dr) == to-rule

and the dot location of `to-dr` is as
described next.

If 

         Base-rule(to-rule) == to-rule and
         Base-rule(dr) == Rule(dr), then

         to-dr == dr

so that the dot stays in the same place.
In this case, the conversion is called *trivial*.
As an example
```
    [X ::= A B . C D] =
         DR-convert([X ::= A B C D], [X ::= A B . C D])
```

If the conversion is not trival,
at least one of

         Base-rule(to-rule) != to-rule or
         Base-rule(dr) != Rule(dr)

is true,
and the conversion of the dot position depends on
the "direction" of the nucleotides involved.

The most complicated case is where

        Base-rule(to-rule) is a nucleotide and
        Base-rule(dr) is a nucleotide

In this case, DR-convert is expanded into a double conversion
such that no more
than one nucleotide is involved at a time.

         DR-convert(to-rule, from-dr) =
           DR-convert(to-rule, DR-convert(Base-rule(from-dr), from-dr))

We'll give an example of this "double conversion"
after we've introduced the simpler
conversions from which it is composed.

In the remaining cases, exactly one of `to-rule` and `Rule(from-dr)`
is a nucleotide.
If that nucleotide's direction is "forward",
then position is counted in traditional left-to-right,
lexical order,
so that 0 is the position before the first symbol of the RHS,
and 1 is the position immediately after the first symbol of the RHS.
As examples,

    [X-L ::= A . B ]
         = DR-convert([X-L ::= A B ], [X ::= A . B C D])
    [X ::= A . B C D]
         = DR-convert([X ::= A B C D], [X-L ::= A . B ])
    [X-L ::= A . B-L ]
         = DR-convert([X-L ::= A B-L ], [X ::= A . B C D])
    [X ::= A . B C D]
         = DR-convert([X ::= A B C D], [X-L ::= A . B-L ])

If the nucleotide's direction is "reverse",
then position is counted in reverse lexical order,
so that 0 is the position after the last symbol of the RHS,
and 1 is the position immediately before the last symbol of the RHS.
As examples,

    [X-R ::= C . D])
        = DR-convert([X-R ::= C D], [X ::= A B C . D])
    [X ::= A B C . D]
         = DR-convert([X ::= A B C D], [X-R ::= C . D])
    [X-R ::= C-R . D])
        = DR-convert([X-R ::= C-R D], [X ::= A B C . D])
    [X ::= A B C . D]
         = DR-convert([X ::= A B C D], [X-R ::= C-R . D])

We now show an example of the most complex case,
where one nucleotide
is converted into another.
We will converted the dotted rule
```
    [X-R ::= B . C D]
```
to another nucleotide rule,
```
    [X-L ::= A B C ]
```
As required, these share a common base rule,
```
    [X-L ::= A B C D]
```
but it is not required that they share a common
base dotted rule,
and in this example, their base dotted rules are different.

The conversion takes place as follows:
```
    DR-convert([X-L ::= A B C ]), [X-R ::= B . C D])
         = DR-convert([X-L ::= A B C ]),
                  DR-convert([X ::= A B C D], [X-R ::= B . C D])
         = DR-convert([X-L ::= A B C ]), [X ::= A B . C D])
         = [X-L ::= A B . C ]
```

Here is another example of a "double conversion"
```
    DR-convert([X-L ::= A B C-L ]), [X-R ::= . B-R C D])
         = DR-convert([X-L ::= A B C-L ]),
             DR-convert([X ::= A B C D], [X-R ::= . B-R C D])
         = DR-convert([X-L ::= A B C-L ]), [X ::= A . B C D])
         = [X-L ::= A . B C-L ]
```

### The straddling dotted rule

The `DR-convert()` pseudo-code function has a useful special case:

         
         Straddle(dr) == DR-convert(Base-rule(dr), dr)

We call `Straddle(dr)`,
the *straddling dotted rule*.
Intuitively,
a dotted rule's straddling rule
is its dotted rule when converted to
to its base rule.
The idea is that
`Straddle(dr)` "straddles" the point at which a nucleotide
is split.

As examples,
```
    Straddle([X-L ::= . A B ]) = [X ::= . A B C D]
    Straddle([X-L ::= A . B ]) = [X ::= A . B C D]
    Straddle([X-L ::= A B . ]) = [X ::= A B . C D]
    Straddle([X-R ::= . C D]) = [X ::= A B . C D]
    Straddle([X-R ::= C . D]) = [X ::= A B C . D]
    Straddle([X-R ::= C D .]) = [X ::= A B C D .]
    Straddle([X ::= . A B C D])    = [X ::= . A B C D]
    Straddle([X ::= A . B C D])    = [X ::= A . B C D]
    Straddle([X ::= A B . C D])    = [X ::= A B . C D]
    Straddle([X ::= A B C . D])    = [X ::= A B C . D]
    Straddle([X ::= A B C D .])    = [X ::= A B C D .]
```

## Start rules

<a name="START-RULES"></a>Marpa
internal grammars are augmented with a start rule
of a very strict form -- a dedicated symbol on its LHS,
and a single symbol on the RHS.
The RHS symbol is usually the start symbol
of the pre-augment grammar.

The start rule of a suffix grammar is the reverse
prediction intra-nucleotide of the pre-strand grammar's
start rule.
For example,
if the start rule of a pre-strand grammar is
```
    start ::= old-start
```
then the start rule of a proper suffix grammar
derived from it will be
```
    start-R ::= old-start-R
```

Success in a parse requires that a completed start rule
be in one of the Earley sets.
This is a necessary condition, but *not* a sufficient
one.
"Success" is a parse is usually more than just a function
of the state of the most recent Earley set.
Applications often impose additional requirements.
A common requirement is that
the completed start rule be in the
Earley set
built after
the last token of input
was consumed.

For example,
an Earley parser
parsing a typical C language source file will
add a completed start rule to its Earley sets
many times before it reaches the end of input.
But a C compiler will only consider the parse successful
if there is a completed start rule in the Earley set
produced
after reading the last token of the C language
source file.

In our example,
the completed start
rule of the pre-strand grammar will be
```
    [ start ::= old-start . ]
```
The completed start
rule of the suffix grammar will be
```
    [ start-R ::= old-start-R . ]
```

## The structure of an bocage

<a name="BOCAGE"></a>Marpa::R2
uses a format called a "bocage" for
abstract syntax forests (ASFs).
Marpa's bocage interface is essentially
the same as Elizabeth Scott's SPFF format.
Marpa has a second syntax for abstract syntax forests,
[externally documented](https://metacpan.org/pod/distribution/Marpa-R2/pod/ASF.pod)
as its `Marpa::R2::ASF` interface,
but `Marpa::R2::ASF`
is for advanced uses.
When this documentation talks about ASFs,
unless otherwise specified,
it refers to the bocage interface.

A bocage consists of nodes.
All nodes are either terminal nodes
or non-terminal nodes.
A terminal node is a 4-tuple of

* A symbol ID, which is one of the symbols
 of the grammar.

* A node value, which may be anything
 meaningful to the application,
 or which may be undefined.

* A start position, which is an input location.

* An end position, which is an input location
  at or after the start position.

A non-terminal node, call it `node`, is a 3-tuple of

* Dotted rule,
  as returned by the
  pseudo-code accessor `DR(node)`.

* Origin,
  as returned by the
  pseudo-code accessor `Orig(node)`.
  The origin is the input location at which
  the dotted rule starts.

* Current location,
  as returned by the
  pseudo-code accessor `Current(node)`.
  This is the location in the input that
  corresponds to the location of the
  dot in the dotted rule's RHS.

It is convenient to use the same terminology for input locations
in both terminal and non-terminal nodes, so that the
start and end position of a terminal node are often
called, respectively, its origin and current location.

The length of a node is the difference
between its origin and its current location,
which must be a non-negative integer.
A node is nulling if and only if the length is zero.
The length
of a terminal node is always one.

A dotted rule notion, when applied to a bocage node,
is equivalent to that dotted rule notion applied
to the dotted rule
of the bocage node.
For example, a medial bocage node is a bocage node
whose dotted rule is a medial.
Similarly, a pseudo-code accessor whose argument
can be a dotted rule, when that argument is a
bocage node, applies to the dotted rule of the
bocage node.
For example, if `node` is an bocage node,
```
     Rule(node) == Rule(DR(node))
```

A rule notion, when applied to a bocage node,
is equivalent to that rule notion applied
to the rule of the dotted rule
of the bocage node.
For example, a start bocage node is a bocage node
in which the rule of its dotted rule is a start rule.
Similarly, a pseudo-code accessor whose argument
can be a rule, when that argument is a
bocage node, applies to the rule of the
dotted rule of the
bocage node.
For example, if `node` is an bocage node,
```
     LHS(node) == LHS(Rule(DR(node)))
```

Every non-terminal node has zero or more "source links",
which describe why the node exists.
If the node is a start rule prediction
its source is not tracked,
and it will have zero links.
All other non-terminal nodes have one or more links.
If `node` is a node,
then `Links(node)` is the pseudo-code
accessor that returns the set of links for `node`.

Every link is a duple,
consisting of
a predecessor and
a cause.
The predecessor and cause
are called children of the node that their
link belongs to.
If node A is a child of node B,
then node B is a parent of node A.

Conceptually, the links indicate how the node
was formed,
with the predecessor describing a
dotted rule with its dot one symbol
earlier in the rule,
and the cause describing the source
of the symbol which allowed the dot
to be moved forward.

If a node is *not* a prediction,

* its cause may be either a terminal node
  or a non-terminal node;

* if its cause is a non-terminal node,
  then its cause must also be a completion;

* its predecessor is always
  a non-terminal node,
  and is never a completion.

If a bocage node *is* a prediction,

* its predecessor will always be undefined;

* it will not have a cause, if the prediction
  is of the start rule;

* if the prediction is not of the start rule,
  its cause will be the medial bocage node
  from which it was created.

Readers familiar with
the links as currently implemented in
Marpa's current implementation
should be aware that
the scheme described here differs.
Marpa currently does not track links
for predictions,
but for the implementation of strand
parsing, it will need to.
Among other reasons,
strand parsing will require a
garbage collection scheme for its
memory management,
and safe garbage collection will require
that all the nodes required
for the creation of a bocage node
be its children.

## Adding a node to the bocage

Nodes are added to the bocage using
the psuedo-code function `Add-node-to-bocage(node)`.
The `node` argument of `Add-node-to-bocage(node)` must be
a bocage node which is
a fully formed "tuple",
and which includes all of its links,
but which is not yet part of the bocage.

When adding a node to a bocage,
no node is ever added twice.
A memoization is used to prevent this.

If `Add-node-to-bocage(new-node)` is called for a node
already in the prefix bocage,
`new-node` itself is ignored is favor of the existing node,
but the links of `new-node` are examined.
Call the existing node, `old-node`.
If a link of `new-node`
is not identical to a link
already in `old-node`,
it is added
to `old-node`.
A node is never allowed to have two identical links.

## Using strand parsing

Before getting into details of the algorithms for forming
a prefix bocage and a suffix parse,
and for winding them together,
it may be useful to outline 
the main intended use.
The archetypal case is the one
in which we parse from left-to-right,
breaking the parse up in pieces
at arbitrary "split points",
and winding the pieces together as
we proceed.

### Initializing an suffix parse

We start by parsing the input normally with the pre-strand
grammar.
This is called the *initial* parse.

All successful parses are assumed to proceed for at least one token
of input.
The initial parse ends

* when it succeeds, as defined by the application;

* when it fails, because the parse cannot continue; or

* when the application has found a desirable "split point"
  and wants to break off the parse.

Regardless of the outcome, we continue into
the following loop, which continues the suffix parse.

### Strand parsing loop

<a name="STRAND-PARSING-LOOP"></a>When
the strand parsing loop begins,
we will have

* a bocage, called the *prefix bocage*; and

* a parse, called the *suffix parse*.

On the first pass through, the prefix bocage will
be empty.
The "suffix" in suffix parse means that the parse
is a suffix relative to a prefix bocage.
This means that the initial parse is also considered
to be a suffix parse,
because the initial parse
*is* a suffix relative to the (at that point empty)
prefix bocage.
A *proper suffix parse* is a suffix parse
which is not the initial parse.

If the suffix parse failed,
we deal with it
using methods like those currently
in Marpa::R2.
If the suffix parse succeeded,
we end the iteration,
and finish the parse as described
[below](#SUCCESSFUL).

At this point we have a suffix parse which neither failed
or succeeded, and a (possibly empty) prefix bocage.
We wind these together as described 
[below](#WINDING).
The result will be a new prefix bocage.

At this point the suffix parse can be discarded.
To save more space, the prefix bocage may be partially
or completely evaluated.

We now restart the parse using the suffix grammar
and the unconsumed input,
as described
[below](SUFFIX-PARSE).

We continue the suffix parse until
success, failure, or the reaching of another split point.
Regardless of the result,
we start a new iteration of the
["Strand parsing loop"](STRAND-PARSING-LOOP).

### Ending the strand parsing loop

As already described above, the strand parsing loop
ends if it encounters success or failure.
Any iteration of the strand parsing loop that
does not succeed or fail must advance at least
one token in the input,
so that the strand parsing loop
always terminates.

## Finding the prefix node

In several cases, we will have
a nucleotide Earley item
in the suffix parse
and will need to find
the forward nucleotide nodes
that it continues from
the prefix bocage.
The forward nucleotide nodes that are
continued by a reverse nucleotide are called its
*prefix nodes*.
There may be many prefix nodes, or none.
The prefix nodes
are returned by the 
pseudo-code accessor `Prefix-nodes(yim)`,
where `yim` is an Earley item.

If `yim` is not a nucleotide,
there are no prefix nodes.
In this case, `Prefix-nodes(yim)`
is undefined.

If `yim` is a nucleotide,
there will be at least one prefix node.
To find the set of prefix nodes,
we follow `yim`'s predecessor links back to
the Earley item, call it `pred-yim`,
whose dotted rule
is `Prediction(Rule(yim))`.
`pred-yim` will always be in the first Earley set
of the suffix parse.
There may be more than one chain of predecessors back
to `pred-yim`, but there will never be more than one `pred-yim`.
The prefix nodes will be the set containing
all `prefix-node` such that
```
     pred-link = [ undef, prefix-node ] and
     pred-link is an element of Links(pred-yim)
```

## Successful parses

<a name="SUCCESSFUL"></a>
If a parse is successful,
there will be a completed start rule,
call it `completed-start-yim`.

* Let

          prefix-nodes = Prefix-nodes(completed-start-yim)

* If `prefix-nodes` is *not* defined,
  this is an initial parse.
  Execute the pseudo-code function

          Recursive-node-add(undef, completed-start-yim, undef)

  Afterwards, the prefix bocage will contain the successful parse,
  and the initial parse may be discarded.
  Do not execute the following steps.

* If `prefix-nodes` *is* defined,
  this is an proper suffix parse, and `prefix-nodes`
  is a set containing a single bocage node.
  Call this node `prefix-node`.

* Execute the pseudo-code function

          Recursive-node-add(prefix-node, completed-start-yim,
              Base-rule(completed-start-yim))

  Afterwards, the prefix bocage will contain the successful parse,
  and the suffix parse may be discarded.

### Offsets

A prefix bocage and
a suffix parse 
will have two different ideas of input location.
To wind them together,
we need to translate between them.
Locations in the prefix bocage
are called
*absolute*, and may be represented
as `Loc(0, forw-loc)` or simply `forw-loc`.
Locations in the suffix parse can be
represented as `Loc(split-offset, suffix-loc)`,
where `split-offset` is the absolute location 
of the split point.

From any `Loc(offset, loc)`,
the absolute location can be calculated as
```
    offset+loc
```
Comparison of locations always uses absolute
location.

The necessary conversions are obvious
and would clutter the pseudo-code,
so they are
usually omitted.
An implementation, of course, would have to
perform them.
As implemented, locations will often be
stored as absolute locations.
Locations stored in the bocage
are always absolute locations.

## Suffix parses

### Creating the suffix grammar

To create a proper suffix parse,
we use a special suffix grammar,
created from the pre-strand grammar.
The suffix grammar is the pre-strand grammar with these changes.

* The pre-strand start symbol is deleted.

* The pre-strand start rule is deleted.

* The reverse nucleobase symbols
  are added.

* The reverse nucleotide rules are added.

* The start rule of the suffix grammar must be
  added.  Its form is
  as described [above](#START-RULES).

The change of start rules between the pre-strand
and the suffix grammar may make some rules inaccessible.
These inaccessible rules can be deleted.
Even so,
the suffix grammar described above may be several
times the size of the pre-strand grammar.
Alternatively, a suffix grammar could be created
on a per-parse basis, adding only

* The reverse nucleotide rules which match forward
  nucleotide rules currently in the prefix bocage.

* Any nucleobase symbols that are on the LHS or RHS
  of those
  reverse nucleotide rules.

### Creating Earley set 0

<a name="EARLEY-SET-0"></a>
In a suffix parse, we proceed using the suffix grammar
and the unconsumed input.
Earley set 0 must be specially constructed.
As a reminded, duplicate items are never added
to an Earley set
and duplicate links are not added to Marpa's
Earley items.
The logic needed to prevent this is not shown.

* Let `worklist` be a stack of symbols,
  initially empty.
  `worklist` will have an associated boolean
  array to ensure that no symbol
  is pushed onto it more than once.

* For every forward nucleotide node,
  call it `forward-node`,
  currently in the prefix bocage.

  + Let 

          reverse-rule = Nucleotide-match(Rule(forward-node))
          suffix-loc-0 = Loc(split, 0)
          new-yim =
              [Prediction(reverse-rule), suffix-loc-0, suffix-loc-0]
          new-link = [undef, forward-node]

  + Add `new-yim-link` to the links for `new-yim`.

  + Add `new-yim` to Earley set 0.

  + Push `new-yim` onto `work-list`.

  + WORK-LIST-LOOP: While `work-list` is not empty,

    - Pop the top Earley item of `work-list`.
      Call it `working-yim`.

    - For every rule, call it `r`, where
      `LHS(r) == Postdot(working-yim)`.

      * Let 

          new-yim =
              [Prediction(r), suffix-loc-0, suffix-loc-0]
          new-link = [undef, working-yim]

      * Add `new-yim` to Earley set 0.

      * Add `new-yim-link` to the links for `new-yim`.

      * Push `new-yim` onto `work-list`.

### After Earley set 0

After Earley set 0,
a suffix parse then continues in the standard
way.
If the original input has been read up to input
location `i`,
then the tokens for location `j` in the suffix
parse are read from original input location
`j+i`.

### Links in the suffix parses

Links in the suffix parses
are as currently implemented for Marpa parses,
except for predictions.
In Marpa's current implementation, predicted
Earley items do not have links.
For suffix parses, they will need to have links.

The predecessor in all prediction links is undefined.
In the initial parse, the cause of the start rule prediction
is also undefined.
All other causes are defined.

For a nucleotide prediction, 
the cause is the forward bocage node from which it
was created.
For a non-nucleotide prediction, 
the cause is the Earley item from which it was created.
The pseudo-code [above](#EARLEY-SET-0)
show how to set the links up correctly in the case
of Earley set 0
of a proper suffix parse.

## Winding

<a name="WINDING"></a>

## Winding together a prefix bocage and a suffix parse

In the following,
we assume that we have stopped the suffix parse
at a point called the split point.
We assume that, at the split point,
the parse has not failed or
succeeded.
This implies that there is at least
one medial Earley item at the split point.

Call the split point, `split`.
Initialize a stack of bocage nodes,
call it `working-stack`,
to empty.

To produce a bocage from the prefix bocage and
the suffix parse, we do the following:

* INTER-LOOP:
  For every medial Earley item, call it `medial-yim`,
  which is in the Earley set at `split`,
  and where `Rule(medial-yim)` is *not* a nucleotide.

  - Let
      
             new-rule = Forward-inter-nucleotide(DR(medial-yim))
             new-node =
                 Recursive-node-add(undef, medial-yim, new-rule)

  - Push new-node onto `working-stack`.

* INTER-NUCLEOTIDE-LOOP:
  For every medial Earley item, call it `medial-yim`,
  which is in the Earley set at `split`,
  and where `Rule(medial-yim)` *is* a nucleotide.

  - Let
      
             straddle-rule = Straddle(DR(medial-yim))
             new-rule = Forward-inter-nucleotide(straddle-rule)

  - For every `prefix-node` in `Prefix-nodes(medial-yim)`

    + Let

             new-node
                 = Recursive-node-add(prefix-node, medial-yim, new-rule)

    + Push new-node onto `working-stack`.

* PREDICTION LOOP:
  For every bocage node,
  call it `inter-node`,
  added in INTER-NUCLEOTIDE LOOP.

  - Note: the values of `inter-node` can be found on
    the `working-stack`, but the values should not be
    popped from the stack, as they will be needed again.

  - RULE-LOOP: For every rule, call it `r`.

    + If `Postdot(DR(inter-node)) != LHS(r)`, continue `RULE-LOOP`.

    + Let

              new-rule = Forward-inter-nucleotide(Prediction(r))
              new-node = [Prediction(new-rule), split, split]

    + `Link-add(new-node, [undef, inter-node])`

    + `Node-to-bocage-add(new-node)`

* INTRA-NUCLEOTIDE LOOP:
  While `working-stack` is not empty:

  - This loop is guaranteed to terminate, because the grammar
    is cycle-free;
    any node added by this loop is the parent
    ("effect") of the node
    that was most recently popped from the stack
    (its "cause");
    and every cause-effect chain will
    eventually reach a effect node that
    is the left nucleotide of the start rule,
    which will not be the cause of any effect node.

  - Pop a node from the working stack.
    Call the popped node `cause-node == [ dr, orig, split ]`.

  - If `Rule(dr)` is a start rule,
    continue `INTRA-NUCLEOTIDE-LOOP`.

  - Follow the predecessors of `cause-node` back to
    its prediction.  Let the links for that predictions
    be the set `prediction-links`.

  - PREDICTION-LINK-LOOP:
    For each link, call it `pred-link`,
    in `predictions-links`.

    + Let `pred-link = [undef, pred-node]`.
      `pred-node` will not be a completion,
      and its postdot symbol will be the base symbol
      of `LHS(dr)`.

               new-rule = Forward-intra-nucleotide(DR(pred-node))
               new-node = [
                   Completion(new-rule),
                   Orig(pred-node), split
               ]

    + `Link-add(new-node, [Clone-node(pred-node, new-rule), cause-node])`
      
    + `Node-to-bocage-add(new-node)`

    + Push `new-node` onto `working-stack`.

  - Continue `INTRA-NUCLEOTIDE LOOP`.

### Rewriting bocage nodes recursively

The pseudo-code function
`Node-rewrite(old-node, rule)`
takes two arguments.
`old-node` must be a node already in the bocage.
`rule` must a rule.
In addition, it must be true that
```
    Base-rule(old-node) == Base-rule(rule)
```
`Node-rewrite(old-node, rule)` returns a new
node, call it `new-node`.
Informally, `new-node` is the same as `old-node`
except that `Rule(new-node) = rule`.

`new-node` is added to the bocage.
After `Node-rewrite(old-node, rule)`, 
`old-node` may or may not be necessary.
`old-node` is not deleted by `Node-rewrite()`.
Cleaning up `old-node`, if necessary, is
left up to the garbage collection scheme.

`Node-rewrite(old-node, rule)` has the same
effect as the following pseudo-code,
which describes it as a recursion.

* Let

          new-node = [
            DR-convert(rule, DR(old-node)),
            Orig(old-node),
            Current(old-node),
               ]

* For every link in `Links(old-node)`

  - Let `link` be `[ pred, cause ]`

  - Let `new-link` be `[ Node-rewrite(pred, rule), cause ]`

  - `Link-add(new-node, new-link)`

+ `Node-to-bocage-add(new-node)`

### Adding bocage nodes recursively

The pseudo-code function
`Recursive-node-add(prefix-node, suffix-element, rule)`
creates a new node, call it `new-node`,
from `suffix-element`.
`suffix-element` may be either an Earley item
or a token.
The new node's rule is taken from the `rule`
argument and,
if `suffix-element` is a continuation of a rule
from the prefix bocage,
the bocage node that it continues
is given via the `prefix-node` argument.

`new-node` is added to the bocage,
along with all its links
and memoizations.
This may require the addition of many other
child nodes to the bocage.

The pseudo-code below describes
`Recursive-node-add()` as a recursion,
because that is easiest conceptually.
In practice,
a non-recursive implementation
is likely to be preferable.

`prefix-node` is defined,
if and only if
`suffix-element` is a non-terminal node,
and `Rule(suffix-element)` is a nucleotide.
If `prefix-node` is defined,
it must be a bocage node such that
`Base-rule(prefix-node) == Base-rule(suffix-element)`.

If `suffix-element` is a non-terminal node,
`rule` may be defined.
If `rule` is defined,
it must be the case that
```
    Base-rule(rule) == Base-rule(suffix-element)
```

* If `suffix-element` is a non-terminal node,
  and `rule` is not defined, then let

          rule == Rule(suffix-element)

* If `suffix-element` is a token, end the `Recursive-node-add()`
  function.  Return `Token-node-add(suffix-element)` as
  its value.

* At this point, we know that `suffix-element`
  is an Earley item.
  For easier reading, let

          yim == suffix-element

* Let `Loc(split-offset, current)`
  be the current location of `yim`.
  Call this location, `current`.

* Let

          new-dr = DR-convert(rule, DR(suffix-element))
          new-node = [ new-dr, orig, current ]

  where `orig` is `Orig(prefix-node)` if
  `Rule(yim)` is a nucleotide,
  and is `Orig(yim)` otherwise.

* At this point we have defined the tuple for the new node --
  we have called it `new-node`.
  We now need to add the links for `new-node`
  before we can add it to the bocage.
  There are many cases,
  so this will be a complicated process.

* If there is no predot symbol
  and `yim` is *not* a nucleotide

  - For each `[undef, pred-cause]`
    in `Links(yim)`.

    - If `Rule(pred-cause)` is *not* a nucleotide,

      + Let `link` be

                   [
                     undef,
                     Recursive-node-add(undef, pred-cause, undef),
                   ]

      + `Link-add(new-node, link)`

    - If `Rule(pred-cause)` *is* a nucleotide,

      + For every `link-prefix-node` in `Prefix-links(pred-cause)`

        * Let `link` be

                     [
                       undef,
                       Recursive-node-add(link-prefix-node, pred-cause,
                          Base-rule(pred-cause)),
                     ]

        * `Link-add(new-node, link)`

  + `Node-to-bocage-add(new-node)`

  + End the `Recursive-node-add()` function.
    Return `new-node` as its value.

* If there is no predot symbol
  and `yim` *is* a nucleotide

  - PREFIX-NODE-LINK-LOOP: For every
    `[new-pred, forw-cause]`
    in `Links(prefix-node)`.

    * Let `link` be `[new-pred, forw-cause]` where

              new-pred = Node-rewrite(pred, rule)

    * `Link-add(new-node, link)`

    * Continue `PREFIX-NODE-LINK-LOOP`.

  + `Node-to-bocage-add(new-node)`

  + End the `Recursive-node-add()` function.
    Return `new-node` as its value.

* Let `predot` be the predot symbol of `yim`.

* If `predot` is a token

  + For every `[pred, succ]` in `Links(yim)`

    - Let `link` be

                 [
                   Recursive-node-add(prefix-node, pred, rule),
                   Token-node-add(predot)
                 ]

    - `Link-add(new-node, link)`

  + `Node-to-bocage-add(new-node)`

  + End the `Recursive-node-add()` function.
    Return `new-node` as its value.

* If `predot` is *not* a nucleobase

    + For every `[pred, succ]` in `Links(yim)`

      - In the previous step, note that `succ` is must be after the reverse nucleobase;
        therefore after the split point;
        therefore entirely inside the suffix parse;
        and therefore `Rule(succ)` will be a non-nucleotide rule.

      - Let `link` be

                 [
                   Recursive-node-add(prefix-node, pred, rule),
                   Recursive-node-add(undef, succ, undef),
                 ]

      - `Link-add(new-node, link)`

    + `Node-to-bocage-add(new-node)`

    + End the `Recursive-node-add()` function.
      Return `new-node` as its value.

* If `predot` *is* a nucleobase

    + LINK-LOOP: For every `[pred, forw-cause]` in the links of `prefix-node`

        - REVERSE-CAUSE-LOOP:
          For every completion,
          call it `rev-cause-yim`,
          whose current location
          is `current`,
          and whose LHS is `predot`

            * `rev-cause-yim`
              must be a nucleotide, because `predot`, its LHS,
              is a nucleobase.

            * If `Nucleotide-match(forw-cause) != Rule(rev-cause-yim)`,
              continue `REVERSE-CAUSE-LOOP`.

            * `Link-add(new-node, [new-pred, new-cause])` where

                     new-pred = Node-rewrite(pred, rule)
                     new-cause = Recursive-node-add(
                         forw-cause, rev-cause-yim, Base-rule(rev-cause-yim))

            * Continue `REVERSE-CAUSE-LOOP`.

        - Continue `LINK-LOOP`.

    + `Node-to-bocage-add(new-node)`

    + End the `Recursive-node-add()` function.
      Return `new-node` as its value.

* In the `Recursive-node-add()` function,
  this point should never be reached.

### Expanding an input token into a bocage node

The pseudo-code function `Token-node-add(tok)`
does the following

- We assume that `tok` is a token from the suffix parse,
  whose symbol is `sym`,
  whose value is `v`,
  whose start location is `start-n`,
  and whose end location is `end.

- We create a new bocage node,
  call it `new-node`,
  of type "Token", where

        new-node = [ sym, v, start, end ]

- `new-node` will have no links.

- `Node-to-bocage-add(new-node)`.

-  End the `Token-node-add()` function, returning
   `new-node` as it value.

## Implementation

For simplicity, the algorithms have been described
in terms of a recursion,
and without some details necessary
for an implementation of acceptable efficiency.

### Memoization

A recursive implementation might have acceptable
speed, but only if the bocage nodes are memoized.
The memoization can be either a hash or an AVL.

Each keys of the memoization will be the signature
of a bocage node.
A bocage node signature
consists of

* Type: Terminal or non-terminal

* Dotted rule

* Origin, as an absolute location

* Dot location, as an absolute location

The values of the memoization must consist of:

* Type: "Bocage node" or "Actual evaluation".

* Actual value if the value type is "Actual evaluation".
  An actual value can be any first-class value
  in the language of the implementation.

* A pointer to bocage node,
  if the value type is "Bocage node".

### Non-recursive implementation

The implementation will require

* A stack of "work items" to be processed.
  Work items are bocage node signatures.
  To avoid repeated lookups,
  or for other efficiencies,
  work items may also contain
  a fixed amount of
  memoized data.

* The memoization of the bocage nodes,
  discussed above.

* A "stack memoization"
  that keeps track,
  by bocage node signature,
  of work items
  already pushed to the stack.
  This prevents a work item from being pushed onto
  the stack twice.

The algorithm then proceeds as follows:

* We initialize the stack of work items with a single item.

* MAIN-LOOP: While the stack of work items is not empty,

    - We initialize a `ready` flag to `TRUE`.

    - Call the current top of stack work item, `work-item`.

    - LINK-LOOP:
      For every bocage node,
      call it `needed-node`,
      that is needed by `work-item`
      for a link,
      and that is not already in the bocage,

      - If `needed-node` is a terminal bocage node,
        create it; add it to the bocage and the bocage
        memoization;
        and continue LINK-LOOP.

      - Set the `ready` flag to `FALSE`.

      - Push a work item for `needed-node`
        on top of the stack,
        if it is not on the stack already.
        We use the stack memoization to track this.

    - If the `ready` flag is `FALSE`,
      continue `MAIN-LOOP`.

    - If we are here,
      then `work-item` is still on top of the stack,
      We pop `work-item` from the top of the stack.

    - We create the new bocage node from
      `work-item`, calling it `new-node`.

    - In the previous steps,
      we made sure that all the
      bocage nodes necessary for `new-node`
      are already in the bocage.
      We now add all the necessary links to `new-node`.

    - We add `new-node` to the bocage,
      continue `MAIN-LOOP`.

## Leo items [TO DO]

## Saving space [TO DO]

## Incremental evaluation [TO DO]

## Theory: suffix grammars

The suffix grammars described in this
document are derived from
the "suffix grammars", whose construction is described in
Grune & Jacobs, 2nd ed., section 12.1, p. 401.

<!---
vim: expandtab shiftwidth=4
-->
