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
with each node containing the Libmarpa rule, following by its
RHS children.

Then the tree should be evaluated left-to-right
bottom-to-top.
At each rule node,
as a first step,
all children which are mortar or hidden symbols
are discarded.

## Intermediate rules

What happens next depends on whether the rule is
semantically active or not.
If the rule is *not* semantically active, then
the non-discarded RHS symbol are
put into a "intermediate result" Lua object,
which is passed as the value.

## Semantically active rules

If the rule *is* semantically active, its children
are first "flattened".
That is, each rule has been packing its children into
an object, which contains the children of other rules
as objects, and so on recursively.
This must now be undone.

In the semantically active rule, we create an "descendants"
stack for the semantics,
proceeding from left to right.
If the child is a terminal, we push it onto the descendants stack.
Otherwise we call the flatten method for a "intermediate result" object,
passing the stack to it.

The flatten method for
each intermediate result object does essentially that same thing,
recursively.
More specifically,
the intermediate result object is an array.
The flatten method proceeds in lexical order through the array.
For each terminal, it pushes it onto the child stack.
(Recall that the "descendants stack" was passed to the flatten
method as an argument.)
Otherwise, the array element must be a "intermediate result" object,
in which case that object's "flatten" method is called,
with the "descendant's stack" as it argument.

For sequence rules, this recursions can be very long.
The net result will be that the descendants stack contains
the non-hidden brick symbols, in lexical order.
These can now be passed as arguments to the semantics.

Since this is a semantically active rule,
its LHS is a brick symbol,
and it maps to the LHS of a Kollos rule.
We look up the semantics for this Kollos rule,
and apply them to its arguments, which are now the
elements of the descendants stack.

The result of the semantically active rule will be a single
value, which we wrap into a singleton "intermediate result" object.
This object becomes the value of the rule.

### Start rule

The grammar is augmented with a start rule.
When its turn to be evaluated comes, it will always have
exactly one child.
This child will be a singleton "intermediate result" object.
Its element is extracted and returned as the value of the parse.

The above may not work for nulling grammars.
This should be handled as a special case.

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
