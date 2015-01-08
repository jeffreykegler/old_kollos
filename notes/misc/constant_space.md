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

For this document,
we assume that a tree is being built, but we won't count its overhead.
That makes sense, because
the purpose of the time complexity comparison is to compare parsers,
and not other things, even when in practice the other things are
almost always done simultaneously.
The overhead of
tree building will be the same for all parsers.

## The idea

The strategy requires Marpa's planned strand parsing facility,
which allows a Marpa parse to be done in pieces,
pieces which can be assembled.
The main idea is to parse the input until we've used a fixed
amount of memory, then create a "strand" from it.
Once we have the "strand", we can throw away the Marpa parse
on which it is based,
with all its memory, and start fresh on a 2nd "strand".

When we have the 2nd "strand",
we can wind it the first strand together,
and throw away the parse on which the 2nd strand is based.
Performing this
process until we've read the entire input
will result in a strand which is the whole parse forest.

If we track memory while creating slices,
we can quarantee that it never gets beyond some fixed size.
In practice, this size will be quite reasonable
and can be configurable.
It's optimum value will be a tradeoff between speed
and memory consumption.

<!---
vim: expandtab shiftwidth=4
-->
