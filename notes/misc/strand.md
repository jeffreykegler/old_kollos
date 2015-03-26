# Strand parsing

This document describes Marpa's planned
"strand parsing" facility.
Strand parsing allows parsing to do done in pieces,
pieces which can then be "wound" together.
The technique bears a slight resemblance to
that for DNA unwinding, rewinding
and transcription,
and a lot of the terminology
for strand parsing
is borrowed
from biochemistry.

## Theory: suffix grammars

In what follows, some sections will,
like this one,
be marked "Theory".
It is safe to skip them.
They record mathematical details,
some of which are important
for ensuring the correctness of the algorithm.

The "transcription grammar" here is based on
the "suffix grammar", whose construction is described in
Grune & Jacobs, 2nd ed., section 12.1, p. 401.
Our purpose differs from theirs, in that

* we want our parse to contain only those suffixes which
    match a known prefix; and

* we want to be able to create parse forests from both suffix
    and prefix, and to combine these parse forests.

Every context-free grammar has a context-free "suffix grammar" --
a grammar, whose language is the set of suffixes of the first language.
That is, let `g1` be the grammar for language `L1`, where `g1` is a context-free
grammar.
(In parsing theory, "language" is an fancy term for a set of strings.)
Let `suffixes(L1)` be the set of strings, all of which are suffixes of `L1`.
`L1` will always be a subset of `suffixes(L1)`.
It can be shown that there is always some context-free grammar `g2`,
whose language is `suffixes(L1)`.

## Notation

Hypenated names are very convenient in what follows,
while subtraction is rare.
In this document,
to avoid confusion,
subtraction will always be
shown as the addition of a negative number.
For example `4+(-1) = 3`.

## Nucleobases, nucleosugars and nucleotides

In order to make the following algorithm appeal to the intuition more,
we use an analogy to DNA transcription and winding.
For this purpose, we borrow some of the specialist terminology
of biochemistry.

A DNA molecule consists of two "strands", which are joined
by "nucleobase pairs".
In DNA, there are four nucleobases: the familiar
cytosine (C), guanine (G), adenine (A) and thymine (T).
In our strand grammars, we will usually need many more
nucleobases.

In DNA, each nucleobase molecule is attached to a sugar to
form a nucleoside.
Biochemists occasionally call this sugar a nucleosugar.
In DNA,
each nucleoside
is attached to
one or more phosphate groups
to form
a nucleotide.
(Some biochemical texts insist there can be only one
phosphate group in a nucleotide.
For our purposes, the difference is not relevant,
and we will let the chemists argue this out among themselves.)

For our purposes,
a *nucleobase* is a lexeme
at which two "strands" touch directly.
There are left and right nucleobases,
which occur on the left edge and right
edge of strands, respectively.

The RHS of a rule contains at most one nucleobase.
If it is a right nucleobase, it will always be
the first symbol of the RHS.
If it is a left nucleobase, it will always be
the last symbol of the RHS.

In a RHS containing a nucleobase,
a symbol is "inside" another if it is in the direction heading away from
the edge.
If the nucleobase on the RHS of a rule is a left nucleobase,
one symbol is inside another one if it to its left.
If the nucleobase on the RHS of a rule is a right nucleobase,
one symbol is inside another one if it to its right.

If symbol `<A>` is inside symbol `<B>`,
then symbol `<B>` is outside of symbol `<A>`.
If a RHS does not contain a nucleobase,
"inside" and "outside" are not defined.

A *nucleosugar* is a non-terminal used in
winding and unwinding strands.
Nucleosugars always occur in a RHS next to,
and inside of, a nucleobase.

A *nucleosymbol* is either a nucleobase or a nucleosugar.
Finally, a *nucleotide* is a rule that contains
a nucleobase.

As a mnemonic, note that
the order from inside to outside,
and the order from smallest to largest,
is the same as the alphabetical order of the terms:
"base", "side" and "tide".

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

## Dotted rules

Dotted rules are of several kinds:

* predictions, in which the dot is before the first RHS symbol;

* completions, in which the dot is after the last RHS symbol; and

* medials, which are those dotted rules which are neither
    predictions or completions.

* penults, which are a special kind of medial,
  in which the dot is just before the last RHS symbol.

If a dotted rule has the dot after a RHS symbol instance,
the predecessor of that dotted rule is the dotted rule
with the dot before that symbol instance --
in
other words, with the dot one position earlier.
If a dotted rule has the dot before a RHS symbol instance,
the predecessor of that dotted rule is the dotted rule
with the dot after that symbol instance --
other words, with the dot one position later.
Predictions do not have predecessors
and completions do not have successors.

## Earley items

As a reminder, an
Earley item, `eim`, consists of

* A dotted rule, `DR(eim)`.

* An origin, `Orig(eim)`, which is the number
  of the Earley set where `eim` starts.

* An current location, `Dot(eim)`, which is the number
  of the Earley set that contains `eim`,
  and which corresponds to the position of the
  dot in the dotted rule.

## Locations

In this document, we will assume there is
one Earley set per input
location.
Usually location is represented by a non-negative
integer.
Because strand parsing uses multiple parses,
our idea of location has to be more complex:
Location is a duple of two non-negative
integers: `Loc(offset, loc)`.
Here `offset` is the first input location
parsed in the relevant strand,
and `loc` is location within the parse.

Absolute location, `abs` is calculated as
```
    abs = offset > 0 ? offset+loc+(-1) : loc
```
Comparison of locations always uses absolute
locations.
In the location `Loc(0, abs-loc)`,
`abs-loc` is equal to the absolute location.

When `offset` is not
zero in `Loc(offset, pos)`,
the location `pos` is somewhat special --
it is reserved for the pseudo-lexeme
in suffix parses.
`Loc(offset, 0)` "disappears" when strands
are wound together, but in the meantime
caution must be exercised
The absolute location of `Loc(offset, 0)`
is undefined when `offset` is non-zero.

As implemented, locations will often be
stored as absolute locations.
Locations in the bocage and in its
AVL index are always absolute locations.

The necessary conversions are obvious
and would clutter the pseudo-code, they are
usually omitted.
An implementation, of course, would have to
perform them.

## Creating the strand grammar

Let our original grammar be `g1`.
We also call `g1` the pre-strand grammar.
We will need to extend `g1` to a
"strand grammar".

We need to define, for every rule in `g1`, two 'nucleotide rules',
a 'left nucleotide' and a 'right nucleotide'.

First, we define our set of "nucleobase symbols".
The purpose of nucleobase symbols is similar to the purpose
of nucleobases in DNA -- they occur where two strand "touch"
and they occur in pairs.
The matching of nucleobase pairs indicates where two strands
should "touch" in order to preserve their information.

Nuclebase symbols
have the form `b42R`,
and `b42L`;
where the initial `b` means "base".
`R` and `L` indicate, respectively,
the right and left member of the base pair.
`42` is an arbitrary number,
chosen to make sure that every base pair is unique.
A nucleobase symbol can occur only once.
They must occur on the outside of a RHS.
(Pedantically, their location defines "inside" and "outside".)

Every pair of nucleotide rules must have a unique pair of nucleobase
symbols.

Nucleosugar symbols exist to allow non-terminals to be split in half.
Like nucleobase symbols, nucleosugars come in right and left versions.
For example, for the symbol `A`,
the nucleosugars will be `A-L` and `A-R`.
The symbol `A` is called by *base symbol*
of the nucleosugars `A-L` and `A-R`.

We will call the original grammar,
before it has strand rules and symbols added to it,
the "pre-strand grammar".
The rules of a pre-strand grammar are pre-strand rules
and the symbols of a pre-strand grammar are pre-strand symbols.

To split rules in half, we use nucleotide rules.
Let one of `g1`'s pre-strand rules be
```
     X ::= A B C
```
Call this rule `rule-X`.

The six pairs of
"nucleotide rules" that we will need for `rule-X` are
```
    1: X-L ::= b1L            X-R ::= b1R A B C
    2: X-L ::= A-L b2L        X-R ::= b2R A-R B C
    3: X-L ::= A b3L          X-R ::= b3R B C
    4: X-L ::= A B-L b4L      X-R ::= b4R B-R C
    5: X-L ::= A B b5L        X-R ::= b5R C
    6: X-L ::= A B C-L b6L    X-R ::= b6R C-R
```
The pairs are numbered 1 to 6, the same number which
is used in the example to uniquely identify the nucleobase
symbols.
`rule-X` is called the "base rule" of these nucleotides.

Pairs 1, 3 and 5 are
"inter-nucleotides" --
nucleotides that split their base rule
at a point between two symbols.
Pairs 2, 4 and 6 are
"intra-nucleotides" --
nucleotides that split their base rule
at a point within a single symbol.

Every nucleotide has a "base dotted rule".
(As a reminder,
a "dotted rule"
is a BNF rule with one of its positions marked with a dot.)

The rule of a nucleotide's "base dotted rule" is the nucleotide's base rule.
The base dotted rule for nucleotide pairs 1 and 2 is
```
    X ::= . A B C
```
The base dotted rule for nucleotide pairs 3 and 4 is
```
    X ::= A . B C
```
The base dotted rule for nucleotide pairs 5 and 6 is
```
    X ::= A B . C
```

A completion is
a dotted rule with the dot
after the last RHS symbol.
In this example, it is
```
    X ::= A B C .
```
A completion is never the base dotted rule
of a nucleotide.

We can ignore completions,
but we do need to deal with predictions,
The inter-nucleotide pair whose base dotted rule has its dot
before the first non-nulled RHS symbol is called the "prediction nucleotide pair".
In this example, the prediction nucleotides are pair 1.

Each pre-strand rule potentially needs `2*n` pairs of nucleotide rules,
where `n` is the number of symbols on the RHS of the
`g1` rule.
Empty rules can be ignored.
We can also ignore any splits that occur before nulling symbols.

The above rules imply that left split rules can be nulling.
In fact,
for every pre-strand rule,
one of the left split rules derived from it must be nulling.
But no right split rule can be nulling.
Informally, a right split rule must represent "something".

## Active strands

An active strand is one capable of being wound together with
another active strand.
An active strand must be forward-active or reverse-active.
A strand can be *both* forward- and reverse-active,
in which case we call it bi-active.
An active strand which is not bi-active
is called single-active.
An inactive strand is the same as an ordinary
parse forest.

A strand is forward-active if it has nucleobases at its right edge.
A strand is reverse-active if it has nucleobases at its left edge.

## Archetypal strand parsing

Before getting into details of the algorithms for forming
and winding strands,
it may be helpful to indicate how they are intended to
be used.
There are many ways in which strand parsing can be used,
but
the archetypal case is that where we
are parsing from left-to-right,
breaking the parse up at arbitrary "split points",
and winding pairs of strands together as
we proceed.

In more detail:

* We start by parsing the input until
    we have an initial single-active forward-active strand,
    or the parse has succeeded,
    or the parse has failed.
    If the parse succeeded or failed,
    we have an inactive strand,
    and we proceed as described in the section titled
    "Producing the ASF".

* We then loop for as long as we can create bi-active strands,
    by parsing the remaining input.

    * We parse the remaining input to create a new strand.

    * If this new strand is not bi-active, we end the loop.

    * At this point,
        we have a single-active forward-active strand
        and a bi-active strand.

    * We wind our two strands together,
         leaving a single-active forward-active strand,
         and continue the loop.

* On leaving the loop, we have two single-active strands, one
    forward-active, one reverse-active.
    We wind these two together to produce an inactive strand.
    Call this the "final strand".
    We proceed as described in the section titled
    "Producing the ASF".

## The structure of an Bocage

Marpa::R2 has two format for abstract syntax forests.
The one
[externally documented](https://metacpan.org/pod/distribution/Marpa-R2/pod/ASF.pod)
as its `Marpa::R2::ASF` interface
is for advanced uses,
and is an upper layer to the undocumented
"bocage" interface.
The bocage interface (which is essentially
the same as Elizabeth Scott's SPFF format)
is the one which will be described here.
An forest for the `Marpa::R2::ASF` interface
can be built from the bocage,
when and if desired.

A bocage consists of nodes.
All nodes are either terminal nodes
or non-terminal nodes.
A terminal node is a 4-tuple of

* A symbol ID, which is one of the symbols
 of the grammar.

* A node value, which may be anything
 meaningful to the application,
 or which may be undefined.

* A start position, which is a G1 location.

* An end position, which is a G1 location
 at or after the start position.

The start position and end position may be
the same, in which case the terminal node
is a nulling node.
The length of the node is the difference
between end position and start position,
which must be a non-negative integer.
A node is nulling if and only if the length is zero.
In normal applications,
the length
of non-nulling terminal nodes
will be one.

A non-terminal node is a 3-tuple of

* Dotted rule.
 As a reminder, a dotted rule is
 a rule of the grammar with one of its
 positions distinguished as the "dot position".

* Origin, that is, the G1 location at which
 the dotted rule starts.

* Dot location, which
 is the G1 location of
 the dotted rule's dot position.

It is convenient to use the same terminology for G1 locations
in both terminal and non-terminal nodes, so that the
start and end position of a terminal node are often
called,respectively, its origin and dot location.

A non-terminal nodes is called a prediction,
a medial and or a completion,
based on their dotted rules.
A prediction node whose dotted rule
is a nucleotide,
will only occur on the active edge of
a strand,
and is called an
active prediction node.
All other prediction nodes
are called inactive prediction nodes.
The information in
inactive prediction nodes
can usually be deduced from the other nodes,
so that inactive prediction nodes are not physically represented
in the bocage.

Every non-terminal node has zero or more "source links",
which describe why the node exists.
If the node is a prediction,
its source is not tracked,
and it will have zero links.
Otherwise, a non-terminal node has one or more links.

Every link is a duple,
consisting of
a predecessor and
a successor.
The predecessor and successor
are called children of the node that their
link belongs to.
If node A is a child of node B,
then node B is a parent of node A.

Conceptually, the links indicate how the node
was formed,
with the predecessor describing a
dotted rule with its dot one symbol
earlier in the rule,
and the successor describing the source
of the symbol which allowed the dot
to be moved forward.

The successor may be either a terminal node
or a non-terminal node.
If the successor is a non-terminal node,
that node must be a completion.

The predecessor is always
a non-terminal node,
and is never a completion.
It may be a prediction,
in which case the node the link points
to will not be physically represented in
the bocage unless it is an active prediction node.

In creating or extending a bocage,
no node is ever added twice.
If a node has more than one source,
the node with, if appropriate, a link
is added by the first source.
Subsequent sources add links,
when appropriate,
to original node.
Also, no link is ever added twice.

### The straddling dotted rule

For winding a prefix and
a suffix together, it will be convenient
to define the *straddling dotted rule*.
Intuitively, the straddling dotted rule of another
dotted rule, call it `dr`,
is a dotted rule whose rule is the base rule
of `Rule(dr)`,
and which has the dot in the corresponding position.

More precisely,
if `Rule(dr)` is not a nucleotide,
then 
```
    Straddle(dr) = dr
```
If `Rule(dr)` is a nucleotide,
then
```
    Rule(Straddle(dr)) = Base-rule(dr)
```
and the dot position
of `Straddle(dr)`
is the same,
relative to the outside of `dr`,
as the dot
position of `dr`.

For instance,
from the example above,
let `dr` be the dotted rule
```
    X-R ::= b4R B-R . C`
```
Call the base dotted rule of `Rule(dr)`,
`base-dr`.
We have
```
    base-dr = [X ::= A . B C]
```
Then, `Straddle(dr)` will be `Rule(dr)`,
with its dot position the same as `dr`,
counted from the outside.
Since `Rule(dr)` is a reverse
nucleotide, its nucleobase is the first
symbol of its RHS.
The nucleobase is always considered
the "inside",
so that
position relative to the outside
is position relative
to the last symbol of the RHS.

In `dr`, the dot is just before
the last symbol of the RHS.
To create the straddling dotted rule,
we start with the base rule,
and put the dot just before
the last symbol of its RHS.
The result is
```
    Straddle(dr) = [X ::= A B . C]
```

`Straddle(dr)` will sometimes be the same as
the base dotted rule,
but often that is not the base.
On one hand,
the stradding dotted rule
and the base dotted rule
will always have the same rule.
But the
the stradding dotted rule
and the base dotted rule
often have
have different dot positions.
For instance,
this is true in the example just given.

As another example, let `dr-forw`
be the dotted rule
```
    X-L ::= A . B-L b4L
```
This time `Rule(dr-forw)` is a forward
nucleotide, so that the nuclebase is at
the right end of the RHS,
and
the "inside" of the RHS is its last symbol.
Therefore the outside of the RHS
is its last symbol.
The dot in `dr-forw` is just after its first
symbol so that,
putting the dot in the same position
in the straddling dotted rule,
we have
```
    Straddle(dr-forw) = [X ::= A . B C]
```

For some more examples let
```
    X-L ::= A B b42L
    X-R ::= b42R C D
```
be forward and reverse inter-nucleotides.
Their base dotted rule is
```
    X ::= A B . C D
```
In that case
```
    Straddle([X-L ::= . A B b42L]) = [X ::= . A B C D]
    Straddle([X-L ::= A . B b42L]) = [X ::= A . B C D]
    Straddle([X-L ::= A B . b42L]) = [X ::= A B . C D]
    Straddle([X-R ::= b42R . C D]) = [X ::= A B . C D]
    Straddle([X-R ::= b42R C . D]) = [X ::= A B C . D]
    Straddle([X-R ::= b42R C D .]) = [X ::= A B C D .]
```

### Expanding a input token into a bocage node

If we have an input token, `tok`,
whose symbol is `sym`,
whose value is `v`,
whose start location is `start`n`,
and whose end location is `end,
we expand it into the terminal bocage node
```
    Top(tok) = [ sym, v, start, end ]
```
It will have no links.
Top(tok) is considered to be the top node of the bocage,
starting from `tok`.

## Producing the ASF from inactive strands

To produce an ASF from an inactive strand,
we must determine if the parse succeeded
or failed.
If there is completed start rule covering the entire
input in the inactive strand,
the parse succeeded.
The completed start rule is an Earley item,
which we can call
`success-eim`.
We expand `success-eim` to a bocage node,
as described above.
In the process, we will have created our
parse forest.

If there is no completed start rule,
the parse is a failure.
To diagnose the failure,
we can produce a parse
forest
using broken left nucleotides.

## Winding together a prefix bocage and a suffix parse

In the following,
we assume that you have stopped the suffix parse
at a point called the split point.
We assume that, at the split point,
the parse has not failed.
This implies that there is at least
one medial Earley item at the split point.

Call the split point, `split`.
To produce a bocage from the prefix bocage and
the suffix parse, we do the following:

* INTER-NUCLEOTIDE LOOP:
  For every medial Earley item, call it `medial-eim,
  which is in the Earley set at `split`

    - Let that medial Earley item be
      `medial-eim == [ dr, orig, split ]`.

    - Let
      
               base-rule = Base-rule(medial-eim)
               straddle-rule = Straddle(dr)
               new-rule = Forward-inter-nucleotide(straddle-rule)
               new-dr = Completion(new-rule)

      For instance, using the example above,
      if `dr` is the dotted rule
      `X ::= A B . C`, then
      `new-dr` is the dotted rule `X-L ::= A B b5L .`.

    - PREFIX-NODE-LOOP:
      For every `prefix-node` in `Prefix-nodes(medial-eim)`

      * Let `orig` be `Orig(prefix-node)` if prefix-node is defined,
        otherwise let `orig = Orig(medial-eim)`.

      * Let `new-node = [new-dr, orig, split]`

      * LINK-LOOP:
        For every link, `[pred, succ]` of `medial-eim`:

                Add-link(new-node, [
                   Recursive-node-add(prefix-node, pred, new-rule),
                   Recursive-node-add(undef, succ, Rule(succ)),
                ])

    - `Node-to-bocage-add(new-node)`

  * PREDICTION LOOP:
  For every medial Earley item in the Earley set at `split`

    - Let that medial Earley item be
      `medial-eim == [ dr, orig, split ]`.

    - Let the postdot symbol in `dr` be `postdot`

    - For every rule with `postdot` as its LHS.

         + Call that rule, `r`.

         + Let `dr` be the prediction dotted rule
           of `r`.

         + Let `lent` be the left inter-nucleotide
           rule of `dr`.

         + Let `lent-eim` be the virtual Earley item
           `[lent-dr, orig, split ]`.
           Expand `lent-eim` into the bocage node, `lent-node`,
           and add it to the bocage,
           as described under
           "Expanding an Earley item into a bocage node"
           above.
           `lent-node` will have no links.

* INTRA-NUCLEOTIDE LOOP:
  Loop once over every node whose dotted rule is a left nucleotide.
  This is done by initializing a stack (the "working stack")
  to those "left nucleotide nodes"
  that were added in the INTER-NUCLEOTIDE LOOP.
  This loop is guaranteed to terminate, because the grammar
  is cycle-free, any node added this loop is the parent
  ("effect") of the node
  that was most recently popped from the stack
  (its "cause")
  and every cause-effect chain will
  eventually reach a effect node that
  is the left nucleotide of the start rule,
  which will not be the cause of any effect node.

    - If the working stack is empty,
      exit INTRA-NUCLEOTIDE LOOP.

    - Pop a node from the working stack.
      Call the current node `cause-node == [ dr, orig, split ]`.
      `dr` will be a left nucleotide penult.
      For instance, `dr` might be the dotted
      rule `X-L ::= A B . b5L`
      from the above example.

    - Let `cause-symbol` be the LHS of `dr`.
      The cause symbol will be a nucleosugar.
      In our example, this symbol would be `X-L`.

    - Let `base-symbol` be the base symbol
      of `cause-symbol`.
      In our example, this symbol would be `X`.

    - If `X` is the start symbol, do not execute
      the following steps.
      Restart INTRA-NUCLEOTIDE LOOP from the beginning.

    - For every Earley item in the Earley set `orig`
      whose postdot symbol is `base-symbol`

      + Let that Earley item be
        `pred-eim = [pred-dr, pred-orig, orig]`.  The
        Earley sets index Earley items by postdot symbol,
        so that `pred-eim` can be found efficiently.
       In our example, `pred-dr` might be
       `U ::= V W . X Y`.

     + Let the dotted rule of `pred-eim` be `pred-dr`.

     * Let `effect-rule` be the left intra-nucleotide
       rule of `pred-eim`.
       In our example,
       `effect-rule` might be
       `U-L ::= V W X-L b42L`.

     * Let `effect-dr` be the penult of `effect-rule`.
       In our example,
       `effect-dr` would be
       `U-L ::= V W X-L . b42L`.

      + Expand `pred-eim` into the bocage node `pred-node`
        as described under
        "Expanding an Earley item into a bocage node"
        above.

      + Create the bocage node `[ effect-dr, pred-orig, split ]`.
        Call this `new-node`.

      + Add `[pred-node, cause-node]` as a link of `new-node`.

      + Push `new-node` onto the working stack.

      + Restart INTRA-NUCLEOTIDE LOOP from the beginning.

## Starting a suffix parse

A suffix parse is a reverse-active strand which continues
another forward-active strand.
The intent will usually be to wind the two strands
together.

### The forward nucleobases

The forward nucleobases are the set of left nucleobases
from the forward-active strand.
The reverse nucleobases are the set of right nucleobases
corresponding to the left nucleobases.
As a reminder, the corresponding right nucleobase
of the left nucleobase `b42L` would be `b42R`,
and vice versa.

### The suffix grammar

To create a suffix parse, we use a special suffix grammar,
created from the pre-strand grammar.
The suffix grammar is the pre-strand grammar with these changes.

* The pre-strand start symbol is deleted.

* The pre-strand start rule is deleted.

* The right nucleosymbols (nucleosugars and nucleobases)
  are added.

* The right nucleotide rules are added.

* The start rule of the suffix grammar is the right
  intra-nucleotide rule whose base dotted rule
  is the prediction start rule of the pre-strand
  grammar.

The suffix grammar described above will be several
times the size of the pre-strand grammar.
Alternatively, a suffix grammar could be created
on a per-parse basis, adding only

* The forward nucleobase symbols

* The right nucleotide rules which contain forward
  nucleobase symbols.

* The right nucleosugars contained in right nucleotide
  rule with contain forward nucleobase symbols.

All pre-strand rules and symbols made inaccessible
could then deleted.
This grammar would be considerably smaller.

### Create Earley set 0

Earley set 0 in the suffix parse
should consist of all the Earley items
of the form `[ nucleo-dr, 0, 0 ]`,
where `nucleo-dr` is prediction of one
of the suffix grammar's nucleotide rules.
Predictions have no links.

### Create Earley set 1

All the Earley items in Earley set 0
will have a right nucleobase as their
postdot symbol.
Earley set 1 is created by reading all
the nucleobase symbols as tokens
with start location 0 and start location 1.
This makes use of Marpa's ambiguous lexing
capability.

### Continuing the suffix parse

The suffix parse then continues in the standard
way.
If the original input has been read up to input
location `i`, then tokens from the original input
at location `j`
are read into the suffix parse as if they
were at location `j-(i+1)`.

## Winding strands together

### Offsets

In winding strands together,
we actually wind a forward-only strand
with a suffix parse.
As implemented, each of these will keep
locations in its own terms,
and these terms will be different.
Locations in the forward-only strand
will be absolute, and may be represented
as `Loc(0, forw-loc)` or simply `forw-loc`.
Locations in the suffix parse will be
represented as `Loc(split-offset, suffix-loc)`,
where `split-offset` is the absolute location 
of the split point.

### Creating nodes that straddle the split point

The function `Recursive-node-add(prefix-node, suffix-node, rule)`
creates a new node from `suffix-node`,
which may be either an Earley item
or a token,
and adds it to the bocage,
along with all its links
and memoizations.
This may require the addition of many other
child nodes to the bocage.

The description describes a recursion,
because that is easiest conceptually.
In practice,
a non-recursive implementation
is likely to be preferable.

`prefix-node` is a bocage node which must
be on the prefix side of the split point.
`prefix-node` may be undefined if 
`suffix-node` is a token, or if
`Rule(suffix-node)` is not
a nucleotide.
`suffix-node`, `rule` and, if defined, `prefix-node`
must all share the same
base rule.

* If `suffix-node` is a token, end the `Recursive-node-add()`
  function.  Return `Token-node-add(predot)` as
  its value.

* Let `predot` be the predot symbol of `yim`.

* If `predot` is a token, end the `Recursive-node-add()`
  function.  Return `Token-node-add(predot)` as
  its value.

* Let `Loc(split-offset, current)`.
  be the dot location of `yim`.
  Call this location, `current`, for short.

* Let `new-dr` be `Rule-dot(rule, yim)`.

* Let `new-node` be

          [ new-dr, orig, current ]

  where `orig` is `Orig(prefix-node)` if
  `Rule(yim)` is a nucleotide,
  and is `Orig(yim)` otherwise.

* If `predot` is a token

  + For every `[pred, succ]` in `Sources(yim)`

    - Let `link` be

                 [
                   Recursive-node-add(prefix-node, pred, rule),
                   Token-node-add(predot)
                 ]

  + `Node-to-bocage-add(new-node)`

  + End the `Recursive-node-add()` function.
    Return `new-node` as its value.

* If `predot` is not a nucleosymbol

    + For every `[pred, succ]` in `Sources(yim)`

          In the previous step, note that `succ` is after all the reverse nucleosymbols,
          and therefore is after the split point and entirely inside the suffix parse.
          `Rule(succ)` will be a non-nucleotide rule.

        - `Link-add(new-node, link)`

    + `Node-to-bocage-add(new-node)`

    + End the `Recursive-node-add()` function.
      Return `new-node` as its value.

* If `predot` is a nucleosugar

    + LINK_LOOP: For every `[pred, forw-cause]` in the links of `prefix-node`

        - REVERSE_CAUSE_LOOP:
          For every completion whose current location
          is `current`,
          and whose LHS is `predot`

            * Call that completion `rev-cause-eim`.
              It must be a nucleotide, because `predot`, it LHS,
              is a nucleosugar.

            * Call its dotted rule `rev-cause-dr`.

            * If Nucleobases-match(forw-cause, rev-cause_eim)`
              is `FALSE`,
              end this iteration
              and start the next iteration
              of RIGHT_CAUSE_LOOP.

            * `Link-add(new-node, [new-pred, new-cause])` where

                     new-pred = Node-revise(pred, rule)
                     new-cause = Recursive-node-add(
                         forw-cause, rev-cause-eim, Base-rule(rev-cause-eim))

            * Start the next iteration of RIGHT_CAUSE_LOOP.

        - Start the next iteration of LINK_LOOP.

    + `Node-to-bocage-add(new-node)`

    + End the `Recursive-node-add()` function.
      Return `new-node` as its value.

* If we are at this point, `predot` must be a nucleobase.
  In this case:

    + LINK_LOOP: For every `[pred, forw-cause]` in the links of `prefix-node`

      * Let `link` be `[new-pred, forw-cause]` where

               new-pred = Node-revise(pred, rule)

      * `Link-add(new-node, link)`

      * Start the next iteration of LINK_LOOP.

    + `Node-to-bocage-add(new-node)`

    + End the `Recursive-node-add()` function.
      Return `new-node` as its value.

## Implementation

For simplicity, the algorithms have been described
in terms of a recursion,
and without some details necessary
for an implementation of acceptable efficiency.

### Memoization

A recursive implementation might have acceptable
speed, but only if the bocage nodes are memoized.
The memoization can be either a hash or an AVL.

The key for a bocage node must consist of

* Type: Terminal or non-terminal

* Dotted rule

* Origin, as an absolute location

* Dot location, as an absolute location

The value of the key-value pair must consist of:

* Type: "Bocage node" or "Actual evalution".

* Actual value if the value type is "Actual evaluation".
  An actual value can be any first-class value
  in the language of the implementation.

* A pointer to bocage node,
  if the value type is "Bocage node".

In the value of the key-value pair,
only one of 
The value of the bocage node can be either the node itself,
or an arbitrary value

### Non-recursive implementation

The implementation will require

* A stack of "work items" to be processed.
  Work items are either Earley items in the suffix,
  or bocage nodes in the prefix.
  Since the number of Earley items in a strand,
  and the number nodes in the bocage, are both know,
  either a fixed size stack or a dynamicly sized one could be used.

* The memoization of the bocage nodes,
  discussed above.

* A "stack memoization"
  that keeps track of work items
  already pushed to the stack.
  This prevents a work item from being pushed onto
  the stack twice.

The algorithm then proceeds as follows:

* We initialize the stack of work items with a single item.

* LOOP: While the stack of work items is not empty,

    - We initialize a `ready` flag to `TRUE`.

    - Call the current top of stack work item, `work-item`.

    - We examine `work-item`, to determine if bocage nodes exist to
      create all the necessary links.

    - Any terminal bocage node that does not exist is created and
      added to the AVL.

    - LINK_LOOP:
      For every bocage node needed for a link:

      * Let `needed-node` be that bocage node.

      * If `link-node` is not already in the
        bocage,

        - We set the `ready` flag to `FALSE`.

        - We push a work item for `link-node`
          on top of the stack,
          if it is not on the stack already.
          We use the stack memoization to track this.

    - If the `ready` flag is `FALSE`,
      we start a new iteration of LOOP.
      We do not perform the following steps.

    - If we are here,
      then `work-item` is still on top of the stack,
      We pop `work-eim` from the top of the stack.

    - We create the new bocage node,
      call it `new-node`.

    - We all the necessary links.
      In the previous steps, we make sure that all the
      bocage nodes necessary will be found in the memoization.

    - We add `new-node` to the bocage,
      and continue with LOOP.

## Saving space [TO DO]

## Incremental evaluation [TO DO]

<!---
vim: expandtab shiftwidth=4
-->
