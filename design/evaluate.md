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

## Performing the evalution

First, the Libmarpa parse should be turned into a tree,
with each node is a libmarpa-node Lua object.
The array of the Lua object should have the Libmarpa rule as its first
first element.
The remaining elements should be its
RHS children.
These children will be represented by other libmarpa-node objects,
if they are non-terminals.
This tree of libmarpa-node objects and terminals
should be evaluated left-to-right,
bottom-to-top.

[ Add stuff from notes ]

### Start rule

The grammar has an augmented start rule of the
form
```
    <augmented start> ::= <old start symbol>
```

The augmented start is evaluation differently from
other rules.
First off, if the parse is nulled (zero length),
the whole evaluation is treated as a special case.
In that case, `<old start symbol>` will have a nulling
semantics.
This nulling semantics is used to determine a value,
and that value becomes the value of the parse.

If the parse is successful,
and is not nulled,
then the only child of the augmented start rule
will be a brick-result object,
and that brick-result object
will be a singleton -- its array
will contain only one element.
That element becomes the value of the parse.

## Futures

The method described above is not the best.
The current SLIF uses a dual-stack mechanism -- one stack
for the arguments to the semantics, and a second one
of rules.
The rules stack contains indexes to the arguments stack.
This is more efficient than the above,
but harder to implement.

One reason not to bother with the dual-stack implementation,
is that there is probably an even better way --
rewriting the ASF logic.
The ASF (abstract syntax forest) logic is
now in the SLIF, and is in Perl,
so it's currently not every efficient.

If the ASF logic were used,
evaluation would take place
by traversing the ASF
top-down.
To iterate the ASF,
the choices at each glade can be tracked using
a stack.

This would have the advantage, that sections of the ASF
whose topmost symbol is "hidden", can be skipped.
In many cases, this can be a major efficiency.
This also open the road to
symbol hiding, and
partial evaluation, as a technique in itself.
