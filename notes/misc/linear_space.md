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

## The method

<!---
vim: expandtab shiftwidth=4
-->
