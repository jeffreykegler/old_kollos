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
where each node is a `libmarpa-node` Lua object.
The array of the `libmarpa-node` object should have
the ID of the Libmarpa rule as its
first element.
The remaining elements should be its
RHS children -- either terminal or non-terminals.
Non-terminals are other `libmarpa-node` objects.
Terminals are nulling symbols or lexemes,
in some suitable representation.
This tree of `libmarpa-node` objects and terminals
should be evaluated left-to-right,
bottom-to-top, as in the following pseudo-code.

```

-- here the 'brick' argument must
-- be a brick Libmarpa symbol
-- from a Libmarpa node
brick_evaluate(brick)
    let arg_array be an empty array
    get rule, child[0], child[1], ... from brick
    child_evaluate(rule, child, arg_array) for child[0], child[1], ...
    get semantics from rule
    get result by applying the semantics to the arguments in arg_array
    wrap the result into a brick object
    return the brick object
end of brick_evaluate method

child_evaluate(rule, child, arg_array)
    from position of child in rule, determine if it is hidden
        if yes, return
    if child is a terminal
        -- terminals are lexemes and nulled symbols
        push value of child onto arg_array
        return
    if child is a brick symbol
        push brick_evaluate(brick) onto arg_array
        return
    -- if we are here, child is a mortar Libmarpa symbol
    mortar_evaluate(child, arg_array)
    return
end of child_evaluate

-- the 'mortar' argument is a Libmarpa mortar symbol
-- the arg_array is an array onto which the argument
--     for the semantics can be pushed, as we find
--     them in left-to-right order
mortar_evaluate(mortar, arg_array)
    -- if we are here, child is a mortar symbol
    get rule, child[0], child[1], ... from mortar
    child_evaluate(rule, child, arg_array) for child[0], child[1], ...
    return
end of mortar_evaluate method

```

### Start rule

The grammar has an augmented start rule of the
form
```
    <augmented start> ::= <old start symbol>
```
This augmented start rule is a special case
for the semantics.

#### Nulled parses

A parse is nulled if it is zero length.
In that case, `<old start symbol>` will have a nulling
semantics.
This nulling semantics is used to determine a value,
and that value becomes the value of the parse.

#### Other parses

If the parse is successful,
and is not nulled,
then the only child of the augmented start rule
will be a Libmarpa brick symbol.
Let `old_start_symbol` be that child.
Then `brick_evaluate(old_start_symbol)`
will return a singleton brick object --
one whose array
contains only one element.
That element becomes the value of the parse.

## Futures

The method described above is not the best possible.
The current SLIF uses a dual-stack mechanism -- one stack
for the arguments to the semantics, and a second one
of rules.
The rules stack contains indexes to the arguments stack.
This is more efficient than the above,
but harder to implement.

I do not bother with the dual-stack implementation,
because there is an even better way --
rewriting the ASF logic in C.
The ASF (abstract syntax forest) logic is
now in the SLIF,
and is written in Perl,
so it is currently not every efficient.

If the ASF logic were used,
evaluation would take place
by traversing the ASF
top-down.
To iterate the ASF,
the choices at each glade can be tracked using
a stack.

Using the ASF's would
allow sections of the ASF
whose topmost symbol is "hidden" to be skipped.
In many cases, this would be a major efficiency.

Using the ASF would open the way to
many other new techniques.
As one small example, symbol hiding
could be used as a technique
for implementing partial evaluation.

<!---
vim: expandtab shiftwidth=4
-->
