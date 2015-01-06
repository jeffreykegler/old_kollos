# Marpa in constant space

This document describes how Marpa can parse a grammar
in constant space,
assuming that Marpa parses that grammar in linear time.
(The grammars Marpa parses in linear time include those in
all grammar classes currently in practical use.)

## What's the point?  Evaluation is linear or worse.

In practice, we never just parse a grammar -- we do so as a step
toward evaluting it, usually into something like a tree.
A tree takes linear space -- O(n) -- or worse -- O(n log n) --
depending on how we count.
Reducing the time from linear to constant in just the parser
does not affect the overall time complexity of the algorithm.
So what's the point?

In fact, in many cases, there may be little or no point.
Compilers incur major space requirements for optimization
and other purposes, and in their context optimizing the parser
for space may be pointless.

But there are applications that
convert huge files into reasonably
compact formats, and they do that without using
a lot of space in their intermediate processing.
Applications that write
JSON and XML databases can be of this kind.
Pure JSON, in fact, is a small, lexing-driven language which really does
not require a parser as powerful as Marpa.
But bringing Marpa's performance as close as possible to that of custom-written
JSON parsers is a useful challenge.

In what follows,
we'll assume that a tree is being built, but we won't count its overhead.
That makes sense, because tree building will be the same for all parsers.

## The idea

The strategy will be to parse the input until we've used a fixed
amount of memory, then create a tree-slice from it.
Once we have the tree-slice, we can throw away the Marpa parse,
with all its memory, and start fresh on a 2nd tree-slice.

Next, we run the Marpa parser to produce a 2nd tree-slice.
When we have the 2nd tree-slice,
we connect it and the first tree-slice.
We can now throw away the 2nd Marpa parse.
We repeat this process until we've read the entire input
and assembled the whole tree.

If we track memory while creating slices,
we can quarantee that it never gets beyond some fixed size.
In practice, this size will be quite reasonable
and can be configurable.
It's optimum value will be a tradeoff between speed
and memory consumption.

## Theory: suffix grammars

In what follows, some sections will,
like this one,
be marked "Theory".
It is safe for to skip them.
They record technical details which are important
in ensuring the correctness of the algorithm.

Every context-free grammar has a context-free "suffix grammar" --
a grammar, whose language is the set of suffixes of the first language.
That is, let `g1` be the grammar for language `L1`, where `g1` is a context-free
grammar.
(In parsing theory, "language" is an fancy term for a set of strings.)
Let `suffixes(L1)` be the set of strings, all of which are suffixes of `L1`.
`L1` will be a subset of `suffixes(L1)`.
Then there is a context-free grammar `g2`, whose language is `suffixes(L1)`.

## Creating the split grammar

The "split grammar" here is based on
the "suffix grammar", whose construction is described in
Grune & Jacobs, 2nd ed., section 12.1, p. 401.
Our purpose differs from theirs, in that

* we want our parse to contain only those suffixes which
    match a known prefix; and

* we want to be able to create trees from both suffix
    and prefix, and to combine these trees.

In order to accomplish our purposes, we need to define
a "split grammar".
Let our original grammar be `g1`.
Ignore, for the moment, the two issues of nullable symbols,
and of empty rules.
We need to define, for every rule in `g1`, two 'split rules',
a `left rule` and a `right rule`.

First, we'll need some new symbols.
For every non-terminal, we will want a left
and a right version.
For example, for the symbol `A`,
we want two new symbols, `A-L` and `A-R`.

We will also defined a new set of "connector symbols",
whose purpose will be to tell us how to reconnect
split rules.
Connector symbols will be defined in right-left pairs.
The pairs of connector symbols will have the form `c42R`,
and `c421L`;
where the initial `c` means "connector";
`R` and `L` indicate, respectively,
the right and left member of the pair;
and `42` represents some arbitrary number,
chosen to make sure that the pair is unique.
Every split rule must use a unique pair of connector
symbols.


Let a `g1` rule be
```
     X ::= A B C
```
The six pairs of 
"split rules" that we will need are
```
    1: X-L ::= c1L            X-R ::= c1R A B C
    2: X-L ::= A-L c2L        X-R ::= c2R A-R B C
    3: X-L ::= A c3L          X-R ::= c3R B C
    4: X-L ::= A B-L c4L      X-R ::= c4R B-R C
    5: X-L ::= A B c5L        X-R ::= c5R C
    6: X-L ::= A B C-L c6L    X-R ::= c6R C-R
```
The pairs are numbered 1 to 6, the same number which
is used in the example to uniquely identify the connector
symbols.

Pairs 1, 3 and 5 represent splits
between symbols -- these will be called "inter-split pairs".
Pairs 2, 4 and 6 represent splits
within symbols -- these will be called "intra-split pairs".
Every pair corresponds to a dotted rule.
A "dotted rule" is the `g1` rule
with one of its positions marked with a dot.
Pairs 1 and 2 correspond to the dotted rule
```
    X ::= . A B C
```
Pairs 3 and 4 correspond to the dotted rule
```
    X ::= A . B C
```
Pairs 5 and 6 correspond to the dotted rule
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
No split pairs correspond to completions.

The inter-split pair for the dotted rule with the dot
before the first RHS symbols is called the "prediction split pair".
In this example, the prediction split pair is pair 1.

Every `g1` rule will need `n` pairs of split rules,
where `n` is the number of symbols on the RHS of the
`g1` rule.
Empty rules can be ignored.

We need a pair of split rules to represent a "split" before the first
symbol of a `g1` rule, but we do not need a pair to represent a
split after the last symbol.
In other words, we need to deal with predictions,
but we can ignore completions.
We can also ignore any splits that occur before nulling symbols.

The above rules imply that left split rules can be nulling --
in fact one of the left split rules must be nulling.
But no right split rule can be nulling.
Informally, a right split rule must represent "something".

For a small grammar, it is not hard to write the above rules by hand.
For large grammars, there is nothing to prevent the rewrite from
being automated.

## Nulling symbols

Above, we assumed that no symbols are nulling.
Where a rule has nulling symbols on its RHS, we
make the following adjustments.

* There are no split pairs for dotted rules
    with the dot before a nulling symbol.

* This implies that the only split pair for
   a nulling rule is the prediction split pair.

## Deriving the left subtree

Call the point at which we choose to split the parse,
the "split point".
At the split point,
we must derive a left subtree.

The following discussion assumes that we know

* the dotted rules that apply at the current location; and

* how they link to child rules and symbols.

At the Libmarpa level both these things are known.
Unfortunately, as of this writing, only the dotted rules
are available at the SLIF level -- not their links.

### Is the parse exhausted?

First, we look for medial dotted rules at the split point.
Dotted rules are of three kinds:

* predictions, in which the dot is before the first RHS symbol;

* completions, in which the dot is after the last RHS symbol; and

* medials, which are those dotted rules which are neither
    predictions or completions.

There may be no medial dotted rules.
In this case the parse is exhausted -- it can go no further.
We do not continue with the following steps.

If there is completed start rule,
the parse was a success,
and we will be able to derive a full tree,
If there is a completion,
other than of the start rule,
we will be able to derive a subtree,
but it will not be a *left* subtree -- it will be the final subtree
and there will be no way of
joining it up with a subtree to its right.

### Medial dotted rules at the split point

At the split point, we look at each of the medial
dotted rules.
For each of these dotted rules:

* Call the LHS of its dotted rule, `medial-LHS`.
   Call its parent dotted rule, `parent-dr`.

* Add the corresponding left inter-split rule
   as a node of the left subtree.
   Call this new node, `new-node`,

Next, for every `new-node` in the list
of nodes just created:

* Let the medial dotted rule for `new-node` be
    `new-dr`.

* If `new-dr` is the cause of an effect,
    let that effect be `effect-dr`.

* If `effect-dr` does not already have
    a left subtree node, create one.
    Call this node, `effect-node`.

* Make `effect-node` a parent of `new-node`
    in the left subtree.

### Theory: Proofs about pre-split symbols

*To prove*: At the split point, all children of medial rules in
the left subtree are pre-split symbols.

*Proof*:
Split-active symbols occur only as part of split rules.
All medial rules are taken from the Earley sets, which
only contain rules from the pre-split grammar.

(Left split rules are added to the left subtree,
but they are always completions at the split point.
Right split rules are used in the suffix grammar,
but they are always joined to a left split rule
and eliminated when creating a left subtree.)

Since all medial rules are from the pre-split grammar,
all of its children are symbols in the pre-split grammar.
*QED*.

*To prove*: No pre-split symbol derives a post-split symbol

*Proof*:
The only rules with
post-split symbols on their LHS are the left and right split rules.
The only rules with
post-split symbols on their RHS are also left and right split rules.
So no rule with a pre-split symbol directly derives a
post-split symbol.
And therefore, by induction, no rule with a pre-split symbol,
no pre-split symbol derives a post-split symbol.
*QED*.

### Derive split point predictions.

We use a "prediction work list", of duples of the form:
`[symbol, parent]`.
To initialize it, for each medial rule from the above step,
we add `[postdot, medial-node]` to the prediction work list,
where `postdot` is the medial rule's postdot symbol,
and `medial-node` is the left subtree node created from it.

Then, for every `[symbol, parent]` in the prediction work list:

* For every `rule` with `symbol` on its LHS:

    + We find the subtree node for the left predicted split rule,
      createing it if it does not already exist.
      Call this node `new-node`.

    + Link `new-node` to `parent`.

    + Where `rule-postdot` is the postdot symbol of `rule`,
      add `[rule-postdot, new-node]` to the prediction work list.

### Intra-split nodes at the split point.

[ *Corrected to here* ]

[ *From here on out this discussion has problems.*
The basis idea is correct, I believe, but a lot of the details
that follow
are missing or wrong. ]

Our connector grammar, `g-conn`, consists of

* All the rules from `g1`, except for the start rule.

* All the connector suffix rules.

* All the connector start rules.
   
The start symbol for `g-conn` is the connector start symbol,
`Start-C`.

## Connector lexemes

As the name suggests,
the connector lexemes will play a big role in connecting
our parses.
For this purpose, we will want to define a notion:
the *connector lexeme of a dotted rule*.
Dotted rules, as a reminder, are rules with a
"current location" marked with a dot.
For example,
```
    X ::= A . B C
```
Call the symbols after the dot, the "suffix" of a dotted rule.
The connector lexeme of a dotted rule is the connector lexeme used
in the connector rule which is derived with the 
same original rule, and which has the same suffix.
For example, the connector lexeme for the dotted rule above
is `Lex-C2`.
The reader may be able to see how these could be used to connect
dotted rules from one parse with connector rules in another.

## The method

Now that we have a connector grammar, we can describe how the method
works.

* First, parse with the original grammar, `g1`, until we decide we've
    used enough space.

* At the last location, look at all the dotted rules.
    Ignore the completions -- those rules with the dot after the last
    symbol of the RHS.
    For the other, get the list of connector lexemes.

* Create a subtree from the parse so far.
    Call this the "prefix subtree".
    Use the connector lexemes to mark those places where more symbols are
    expected.
    We call the locations of the connector lexemes,
    the "right edge" of the prefix tree.

* Throw away the current Marpa parse, releasing its space.

* Start a new Marpa parse, using the connector grammar, `g-conn`.
    At its first location, read all the connector lexemes from the
    previous grammar.  Marpa allows ambiguous lexemes, so this can be done.

* Resume parsing, with the new "connector" parser and the real input.

* When enough memory has been used, stop.
    Produce a new subtree from the connector parse.
    Call this the "connector subtree".
    The connector lexemes in the connector subtree
    mark its "left edge".
    Connect these with the "right edge"
    of the prefix subtree 
    to join the two subtrees together.

* Throw away the connector parse, releasing its space.

* If the entire input has been read,
    this newly joined subtree is the full tree for the parse.
    We are done.

* If there is more input to be read,
    use the newly joined subtree
    as the prefix subtree for the next phase.
    Mark its "right edge".

* Repeatedly do connector parses, and connect the subtrees
    at their edges,
    until we reach the end of the input.

## Some details

It would be quite possible, for example, to modify Marpa
so that it monitors memory and, if usage passes a limit,
switches to a connector grammar,
creating it on the fly.
If the subtrees are standard AST's it will be clear
how to connect them.

It's possible the same connector lexeme can appear more than once
on the right edge of the prefix subtree,
as well as on left edge of the connector subtree.
In these cases, the general solution is to make *all* possible connections.

<!---
vim: expandtab shiftwidth=4
-->
