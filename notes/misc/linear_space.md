# Marpa in constant space

This document describes a method for using Marpa to parse grammars
in constant space, if it parses that grammar in linear time.
The grammars Marpa parses in linear time include those in
all the
grammar classes currently in practical use.

## What's the point?  Evaluation is linear or worse.

In practice, you never just parse a grammar -- you do so as a step
toward evaluting it, usually into something like a tree.
A tree takes linear space -- O(n) -- or worse -- O(n log n) --
depending on how you count.
Reducing the time from linear to constant in just the parser
does not affect the overall time complexity of the algorithm.
So what's the point?

In fact, in many cases, there may be little or not point.
Compilers incur major space requirements for optimization
and other purposes, and in their context optimizing the parser
for space may be pointless.

But some applications converting huge files into reasonably
compact formats, and without using any space intensive intermediate processing.
JSON or XML databases can be files of this sort.
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

## Creating the suffix grammar

Here's how we create a suffix grammar.
In fact, since our purpose is not theoretical,
but practical, we'll defined, not just a suffix grammar,
but a suffix grammar with "connectors", which allow a suffix grammar
to be "connected" to a prefix grammar.

<!---
vim: expandtab shiftwidth=4
-->
