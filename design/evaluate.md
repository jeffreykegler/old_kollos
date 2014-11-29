# Kollos: evaluation

This document describes how evaluation will be done
in the LUIF.
It assumes you've read the document on grammar
rewrites.

Libmarpa does much of the evaluation work for the
LUIF, but there is the issue of undoing the grammar
rewrites.
This is necessary, because the semantics are defined
in terms of Kollos rules and symbols,
while Libmarpa deals with Libmarpa rules
and symbols.

## Futures

The method described above is not the best,
but it leverages existing Libmarpa.
Better would be to rewrite the ASF logic,
now in the SLIF, into C (or perhaps initially,
Lua) and then evaluate by traversing the ASF
top-down.
To iterate the ASF,
a stack of the choices at each glade can be used.

This would have the advantage, that sections of the ASF
whose topmost symbol is "hidden", can be skipped.
In many cases, this can be a major efficiency.
This also open the road to
symbol hiding, and
partial evaluation, as a technique in itself.
