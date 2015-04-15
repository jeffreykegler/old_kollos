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
and a 6-tuple is a block if and only'
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
    pow2(5) == 3
    pow2(6) == 3
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
converted to obey this resriction.
The procedure in this document
reduces sequence rules to BNF
rules show RHS is not longer
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
    Reduce( seq, item, 0, inf, sep, sep_type )
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

### Eliminate liberal separation

If we have
```
    Reduce( seq, item, m, n, sep, 'liberal' )
```
we convert it into
```
    seq ::= sym1
    seq ::= sym2
    Reduce( sym1, item, m, n, sep, 'proper' )
    Reduce( sym2, item, m, n, sep, 'terminator' )
```

### Eliminate termination

If we have
```
    Reduce( seq, item, m, n, sep, 'terminator' )
```
we convert it into
```
    seq ::= sym1 sep
    Reduce( sym1, item, m, n, sep, 'proper' )
```

For the rest of this procedure, we can assume
that separation is either `proper` or `none`.

#### Eliminate nullables

If we have
```
    Reduce( seq, item, 0, n, sep, seq_type )
```
we convert it into
```
    seq ::= 
    seq ::= sym1
    Reduce( sym1, item, 1, n, sep, 'proper' )
```

We may now assume that the minimum of our
6-tuple is at least 1.

### Normalize separated ranges

If we have
```
    Reduce( seq, item, m, n, sep, 'proper' )
```
where m is 2 or more,
we convert it into a block and a range:
```
    seq ::= sym1 sym2
    Reduce( sym1, item, m, m, sep, 'terminator' )
    Reduce( sym2, item, 1, n-m, sep, 'proper' )
```

### Normalize unseparated ranges

If we have
```
    Reduce( seq, item, m, n, 'nil', 'none' )
```
where m is 2 or more,
we convert it into a block and a range:
```
    seq ::= sym1 sym2
    Reduce( sym1, item, m, m), 'nil', 'none' )
    Reduce( sym2, item, 1, n-m, nul, 'none' )
```

### Eliminate separated open ranges

As a result of the above steps,
all ranges now have a minimum of exactly 1.

If we have
```
    Reduce( seq, item, 1, 'inf', sep, 'proper' )
```
we reduce it to a left recursion:
```
    seq ::= item
    seq ::= seq sep item
```

### Eliminate unseparated open ranges

If we have
```
    Reduce( seq, item, 1, 'inf', 'nil', 'none' )
```
we reduce it to a left recursion:
```
    seq ::= item
    seq ::= seq item
```

### Some definitions


The range `(m,n)`
is called a block if `m` and `n`
are equal.
A block is called an "j-block",
for some integer `j`,
if `n` is equal to `j`.
The range `(m,n)`
is called a span if `m` and `n`
if it is not a block.
If a range is a span,
then we know that `n` is greater
than `m`.
A span is called an "j-span",
for some integer `j`,
if `n` is equal to `j`.

### Eliminate large spans

As a reminder,
at this point all spans are normalized --
that is, their minimum is 1.
Also, as a result of the previous steps,
all ranges are now closed.

If we have
```
    Reduce( seq, item, 1, n, sep, 'proper' )
```
where n is greater than 2,
we binarize it into a choice of two
smaller ranges:
```
    seq ::= sym1
    seq ::= sym2
    Reduce( sym1, item, 1, pow2(n), sep, sep_type )
    Reduce( sym2, item, 1, n-pow2(n), sep, sep_type )
```

### Eliminate spans

Since `Reduce()` is recursive,
the previous step will eliminate all spans
whose maximum is greater than 2.
So the only possible span at this point is
```
    Reduce( seq, item, 1, 2, sep, sep_type )
```
which we convert to a choice of blocks:
```
    seq ::= sym1
    seq ::= sym2
    Reduce( sym1, item, 1, 1, sep, sep_type )
    Reduce( sym2, item, 2, 2, sep, sep_type )
```

With this step, we have eliminated all spans.
Only blocks remain to be reduced
into BNF rules.

### Eliminate large blocks

If we have
```
    Reduce( seq, item, n, n, sep, 'proper' )
```
where n is more than 2,
we binarize it into a sequence of two
smaller blocks:
```
    seq ::= sym1 sym2
    Reduce( sym1, item, pow2(n), pow2(n), sep, 'termination' )
    Reduce( sym2, item, n-pow2(n), n-pow2(n), sep, 'proper' )
```

If we have
```
    Reduce( seq, item, n, n, 'nil', 'none' )
```
where n is more than 2,
the conversion is
```
    seq ::= sym1 sym2
    Reduce( sym1, item, pow2(n), pow2(n), 'nil', 'none' )
    Reduce( sym2, item, n-pow2(n), n-pow2(n), 'nil', 'none' )
```

### Eliminate separated 2-blocks

Again,
since `Reduce()` is recursive,
the previous step converted all blocks to blocks
whose length is at most 2.

If we have
```
    Reduce( seq, item, 2, 2, sep, 'proper' )
```
we reduce it to
```
    seq ::= item sep item
```

If we have
```
    Reduce( seq, item, 2, 2, 'nil', 'none' )
```
we reduce it to
```
    seq ::= item item
```

### Eliminate all blocks

At this point the only 6-tuples left to
reduce to BNF rules,
are 1-blocks.

If we have
```
    Reduce( seq, item, 1, 1, sep, sep_type )
```
we reduce it to
```
    seq ::= item
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
    Reduce( seq, item, 0, inf, sep, sep_type )
```
the algorithm should first look in the memoization
for the 5-tuple composed of the its last 5 elements
```
    [ item, 0, inf, sep, sep_type ]
```
If this 5-tuple is present in the memoization,
its value of the memoization
will be the value of `seq` for a previous call
of `Reduce()` with this 5-tuple.
The memoized value
value of `seq` of `seq` should be used
as the new value of `seq`,
and the steps of `Reduce()`
for that 5-tuple should not be re-run.

If the 5-tuple is not present,
the steps of `Reduce()`,
as described above,
should be performed.
The 5-tuple
should then be added as a key
in the memoization,
with the new value of `seq` as the key's
value.

<!---
vim: expandtab shiftwidth=4
-->
