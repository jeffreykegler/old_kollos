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

In fact, in many cases, there may be little or not point.
Compilers incur major space requirements for optimization
and other purposes, and in their context optimizing the parser
for space may be pointless.

But there are applications that
convert huge files into reasonably
compact formats, and that do without using
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

## A bit of theory

Every context-free grammar has a context-free "suffix grammar" --
a grammar, whose language is the set of suffixes of the first language.
That is, let `g1` be the grammar for language `L1`, where `g1` is a context-free
grammar.
(In parsing theory, "language" is an fancy term for a set of strings.)
Let `suffixes(L1)` be the set of strings, all of which are suffixes of `L1`.
`L1` will be a subset of `suffixes(L1)`.
Then there is a context-free grammar `g2`, whose language is `suffixes(L1)`.

## Creating the connector grammar


Since our purpose is not theoretical,
but practical, we will show how to create,
not just a suffix grammar,
but a "connector grammar", a grammar with not just
suffixes,
but all "connectors"
that allows us to join it to
a "prefix" parse.

Creating the "connector grammar" from our original grammar is not hard,
and could be automated.
We need some new "connector rules" which are rules with a new LHS,
and whose RHS is a "connector lexeme" plus the suffix of the RHS of one of the grammar's
original rules.
No connector rules should be created for empty rules.

For example, let `g1` be our original grammar and assume it contains the rule
```
     X ::= A B C
```
These are the new connector suffix rules
```
    LHS-C1 ::= Lex-C1 A B C
    LHS-C2 ::= Lex-C2 B C
    LHS-C3 ::= Lex-C2 C
```
Here
`LHS-C1`,
`LHS-C2` and
`LHS-C3` are the "connector LHS symbols";
and
`Lex-C1`,
`Lex-C2` and
`Lex-C3` are the "connector lexemes".
For every original rule with `n` symbols on its RHS,
there will be `n` new connector rules.

We also want to define a "connector start symbol",
call it `Start-C`,
and "connector start rules", which are rules of the form
```
    Start-C ::= LHS-C1
    Start-C ::= LHS-C2
    Start-C ::= LHS-C3
    [ ... ]
```
There is one connector start rule for every connector LHS symbol.


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

* Start a new Marpa parse, using the connector grammar, 'g-conn`.
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
