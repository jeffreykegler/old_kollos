# Kollos: sequence rule rewrite

This document describes how the KHIL rewrites
sequence rules for the KIR.
Sequence rules are represented as a 6-tuple
```
    [ seq, item, lo, hi, sep, sep_type ]
```
where

* `seq` is the symbol for the sequence

* `item` is the symbol for item to be repeated

* `lo` is an integer representing the minimum number
  of repetitions

* `hi` is either an integer representing the maximum number
  of repetitions, or `inf` indicating that the
  number of repetitions is unlimited

* `sep` is an optional separator symbol

* `sep_type` is the type of separation,
  which is one of

  - `none`, which means no separation,
    and which is allowed if and only if
    `sep` is not defined;

  - `proper`, which means the separator
    must occur only between
    `item`'s;

  - `terminator`, which means the separator
    is in fact a terminator, and must come
    after every `item`; or

  - `liberal`, which means separation may
    be either `proper` or `terminator`,
    at the user's choice.

The minimum and maximum elements
of a 6-tuple are its range.
The range `m,n`
is called open if `n` is `inf`.
The range `m,n`
is called closed if `n` is an integer.

The range `m,n`
is called a block if it is closed
and its length is equal to 1.
A block is called a "j-block",
for some integer `j`,
if its maximum is equal to `j`.

The range `m,n`
is called a span if it is open,
or if its length is equal to 1.
A span is called a "j-span",
for some integer `j`,
if `n` is equal to `j`.

A range notion is true of a 6-tuple,
if and only if
it is true of the range of the 6-tuple.
As examples, a 6-tuple is open if
and only if its range is open,
and a 6-tuple is a block if and only
if its range is a block.

Letting `sep` and `sep_type` stand in
for the appropriate type of separation,
rules of the form
```
    seq ::= item*
    seq ::= item+
    seq ::= item?
```
are treated, respectively, as the 6-tuples
```
    [ seq, item, 0, inf, sep, sep_type ]
    [ seq, item, 1, inf, sep, sep_type ]
    [ seq, item, 0, 1, sep, sep_type ]
```

We define
the function
`pow2(X)` to be the largest power of two
strictly less than `X`.
That is
```
    pow2(2) == 1
    pow2(3) == 2
    pow2(4) == 2
    pow2(5) == 4
    pow2(6) == 4
```
and so on.
We leave
`pow2(0)`
and `pow2(1)` undefined.

## Binarization and Chomsky form

The naive way of to rewrite a span is to
convert it to a block, one
for each possible length.
For a long span, such as `42,8675309`,
this would result in a number rules
which is linear in the length of the span.

The procedure in this document uses binarization --
it repeatedly divides the span into halves.
This converts a span in a number of rules
that is logarithmic in the length of the span.

Chomsky showed that any context-free
grammars can be rewritten into a from
where all of its rules
have RHS's
whose length is two or less.
Libmarpa's internal form will eventually be
converted to obey this restriction.
The procedure in this document
reduces sequence rules to BNF
rules whose RHS is not longer
than two symbols,
with a few exceptions.
The exceptions are cases
where a very short RHS
is a real problem for readability.

Conversion to Chomsky form during this
rewrite is not necessary --
it would be done at a later point anyway.
But it is best to shorten the RHS's in a
context which
is aware of the intuitive structure of the grammar.

## Reducing sequence rules to BNF rules

The rewrite will be a recursive function,
which we will call, `Reduce()`, so that
```
    seq = Reduce( item, 0, inf, sep, sep_type )
```
produces the rewrite for one or our 6-tuples.

The symbol called `seq`
will be
the LHS of the "highest level",
"top", or "parent"
rule in that step of the
rewrite.
Other symbols,
represented as
`sym1`, `sym2`, etc.,
may need to
be introduced.
In the actual rewrite,
the actual names of the symbols
represented as
`sym1`, `sym2`, etc.,
must be
unique to that step of the rewrite.

The algorithm must track
the current rules,
so that no rule is ever added
more than once.
It must also memoize the results of
`Reduce()`.

### Format

Each step will state a
condition,
which will be a `Reduce()`
pseudo-code function
in a restricted form.

Following the condition
will be the procedure to be followed
if it holds.
This procedure
will consist of zero or
more recursive calls to `Reduce()`,
of the form,
```
    Let sym1 = Reduce( item, m, n, sep, 'proper' )
```
followed by one or more BNF rules
to be added.
The addition of BNF rules is stated in the form
```
    Add rule seq ::= sym1
```
The values produced
by the `Reduce()` calls
are used in the BNF rules.

Only the procedure in the first
condition that applies
is carried out,
so that each pass through this logic
invokes the procedure
of one and only one of the steps.

The assumption is made that the
result of the `Reduce()` functions
can be used in the BNF rules.
In all the procedures, this is always
the case, since the BNF rules are either created
at that point,
or else exactly
duplicate other BNF rules already created.

An exception, however is the top-level `Reduce()`
call of the sequence rule, whose result must be
fit into an existing context.
That context may want the LHS of the top-level
rule to have a pre-determined name,
call it `wanted-seq`.
If `Reduce()` instead returns `returned-seq`,
the incompatibility can worked around
by adding a unit rule:
```
    wanted-seq ::= returned-seq`
```

### Eliminate liberal separation

If we have
```
    Reduce( item, m, n, sep, 'liberal' )
```
our procedure is
```
    Let sym1 = Reduce( item, m, n, sep, 'proper' )
    Let sym2 = Reduce( item, m, n, sep, 'terminator' )
    Add rule seq ::= sym1
    Add rule seq ::= sym2
```

### Eliminate termination

If we have
```
    Reduce( item, m, n, sep, 'terminator' )
```
our procedure is
```
    Let sym1 = Reduce( item, m, n, sep, 'proper' )
    Add rule seq ::= sym1 sep
```

For the following steps, we can now assume
that separation is either `proper` or `none`.

#### Eliminate nullables

If we have
```
    Reduce( item, 0, n, sep, seq_type )
```
our procedure is
```
    Let sym1 = Reduce( item, 1, n, sep, 'proper' )
    Add rule seq ::= 
    Add rule seq ::= sym1
```

We may now assume that the minimum of our
6-tuple is at least 1.

### Normalize separated ranges

If we have
```
    Reduce( item, m, n, sep, 'proper' )
```
where m is 2 or more,
we convert it into a block and a range:
```
    Let sym1 = Reduce( item, m, m, sep, 'terminator' )
    Let sym2 = Reduce( item, 1, n-m, sep, 'proper' )
    Add rule seq ::= sym1 sym2
```

### Normalize unseparated ranges

If we have
```
    Reduce( item, m, n, 'nil', 'none' )
```
where m is 2 or more,
we convert it into a block and a range:
```
    Let sym1 = Reduce( item, m, m, 'nil', 'none' )
    Let sym2 = Reduce( item, 1, n-m, 'nil', 'none' )
    Add rule seq ::= sym1 sym2
```

### Eliminate separated open ranges

As a result of the above steps,
all ranges now have a minimum of exactly 1.

If we have
```
    Reduce( item, 1, 'inf', sep, 'proper' )
```
we reduce it to a left recursion:
```
    Add rule seq ::= item
    Add rule seq ::= seq sep item
```

### Eliminate unseparated open ranges

If we have
```
    Reduce( item, 1, 'inf', 'nil', 'none' )
```
we reduce it to a left recursion:
```
    Add rule seq ::= item
    Add rule seq ::= seq item
```

### Eliminate large separated spans

As a reminder,
at this point all spans are normalized --
that is, their minimum is 1.
Also, as a result of the previous steps,
all ranges are now closed.

If we have
```
    Reduce( item, 1, n, sep, 'proper' )
```
where n is greater than 2,
we binarize it into a sequence of two
smaller ranges:
```
    Let sym1 = Reduce( item, 1, pow2(n), sep, 'terminator' )
    Let sym2 = Reduce( item, 0, n-pow2(n), sep, 'proper' )
    Add rule seq ::= sym1 sym2
```

### Eliminate large unseparated spans

If we have
```
    Reduce( item, 1, n, 'nil', 'none' )
```
where n is more than 2,
the conversion is
```
    Let sym1 = Reduce( item, 1, pow2(n), 'nil', 'none' )
    Let sym2 = Reduce( item, 0, n-pow2(n), 'nil', 'none' )
    Add rule seq ::= sym1 sym2
```

### Eliminate spans

Since `Reduce()` is recursive,
the previous step will eliminate all spans
whose maximum is greater than 2.
So the only possible span at this point is
```
    Reduce( item, 1, 2, sep, sep_type )
```
which we convert to a choice of blocks:
```
    Let sym1 = Reduce( item, 1, 1, sep, sep_type )
    Let sym2 = Reduce( item, 2, 2, sep, sep_type )
    Add rule seq ::= sym1
    Add rule seq ::= sym2
```

With this step, we have eliminated all spans.
Only blocks remain to be reduced
into BNF rules.

### Eliminate large separated blocks

If we have
```
    Reduce( item, n, n, sep, 'proper' )
```
where n is more than 2,
we binarize it into a sequence of two
smaller blocks:
```
    Let sym1 = Reduce( item, pow2(n), pow2(n), sep, 'terminator' )
    Let sym2 = Reduce( item, n-pow2(n), n-pow2(n), sep, 'proper' )
    Add rule seq ::= sym1 sym2
```

### Eliminate large unseparated blocks

If we have
```
    Reduce( item, n, n, 'nil', 'none' )
```
where n is more than 2,
the conversion is
```
    Let sym1 = Reduce( item, pow2(n), pow2(n), 'nil', 'none' )
    Let sym2 = Reduce( item, n-pow2(n), n-pow2(n), 'nil', 'none' )
    Add rule seq ::= sym1 sym2
```

### Eliminate separated 2-blocks

Again,
since `Reduce()` is recursive,
the previous step converted all blocks to blocks
whose length is at most 2.

If we have
```
    Reduce( item, 2, 2, sep, 'proper' )
```
we reduce it to
```
    Add rule seq ::= item sep item
```

If we have
```
    Reduce( item, 2, 2, 'nil', 'none' )
```
we reduce it to
```
    Add rule seq ::= item item
```

### Eliminate all blocks

At this point the only 6-tuples left to
reduce to BNF rules,
are 1-blocks.

If we have
```
    Reduce( item, 1, 1, sep, sep_type )
```
we reduce it to
```
    Add rule seq ::= item
```

With this final step, we have reduced all sequence
rules to BNF rules.

## Implementation

### Avoid duplication of rules

In the above, it is assumed that duplicate rules
are not added.
This imposes no additional burden on the KHIL,
which needs to avoid duplicating rules in
general,
not just for this rewrite of sequence rules.

### Memoize calls to `Reduce()`

Reductions of the 6-tuples should be memoized.
That is, for every call to `Reduce()`,
```
    Reduce( item, 0, inf, sep, sep_type )
```
the algorithm should first look in the memoization
for the 5-tuple composed of its arguments
```
    [ item, 0, inf, sep, sep_type ]
```
If this 5-tuple is present in the memoization,
its value of the memoization
will be the value returned by the previous call
of `Reduce()` with this 5-tuple.
The memoized return value
as the new return value,
and the procedure of `Reduce()`
for that condition should *not*
be carried out.

If the 5-tuple is not present,
the procedure for the appropriate
condition,
as described above,
should be carried out,
and its return value
should be recorded.
A new key-value pair should then
be added to the memoization,
where the
5-tuple is the key half of the key-value pair,
and the procedure's return value
is the value half
of the key-value pair.

<!---
vim: expandtab shiftwidth=4
-->
