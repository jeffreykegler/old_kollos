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

## Chomsky form

Chomsky showed that context-free
grammars can be reduced
to rules whose length is two or less.
Libmarpa's internal form will eventually be
converted to obey this resriction.
The procedure in this document
rewrites rules into a form
where no RHS is longer
than two symbols,
unless such a rewrite does real violence
to the clarity of the result.

In fact,
conversion to Chomsky form during this
rewrite will never be necessary --
it would be done at a later point anyway.
But it is best to shorten the RHS's in a
context which
is aware of the intuitive structure of the grammar.

## Describing the rewrite

The rewrite will be a recursive function,
which we will call, `Doseq()`, so that
```
    Doseq( seq, item, 0, inf, sep, sep_type )
```
produces the rewrite for one or our 6-tuples.
In the rewrite, one or more new symbols will
be introduced.
In the descriptions below,
one of these will be represented as `seq`,
and the others will be represented by names
of the form
`sym1`, `sym2`, etc.
In fact, the actual rewrite,
these names
must such that they are
unique to that step of the rewrite.

The symbol called `seq`
will be
the LHS of the "highest level"
rule in that stage of the
rewrite.

The algorithm must track
the current rules,
so that no rule is ever added
more than once.
It must also memoize the results of
`Doseq()`.

### Eliminate liberal separation

If we have
```
    Doseq( seq, item, m, n, sep, 'liberal' )
```
we convert it into
```
    seq ::= sym1
    seq ::= sym2
    Doseq( sym1, item, m, n, sep, 'proper' )
    Doseq( sym2, item, m, n, sep, 'terminator' )
```

### Eliminate termination

If we have
```
    Doseq( seq, item, m, n, sep, 'terminator' )
```
we convert it into
```
    seq ::= sym1 sep
    Doseq( sym1, item, m, n, sep, 'proper' )
```

For the rest of this procedure, we can assume
that separation is either `proper` or `none`.

### Eliminate nullables

If we have
```
    Doseq( seq, item, 0, n, sep, seq_type )
```
we convert it into
```
    seq ::= 
    seq ::= sym1
    Doseq( sym1, item, 1, n, sep, 'proper' )
```

We may now assume that the minimum of our
6-tuple is at least 1.

## Normalize separated ranges

If we have
```
    Doseq( seq, item, m, n, sep, 'proper' )
```
where m is 2 or more,
we convert it into
```
    seq ::= sym1 sym2
    Doseq( sym1, item, m, m, sep, 'terminator' )
    Doseq( sym2, item, 1, n-m, sep, 'proper' )
```

## Normalize unseparated ranges

If we have
```
    Doseq( seq, item, m, n, 'nil', 'none' )
```
where m is 2 or more, we convert it to
we convert it into
```
    seq ::= sym1 sym2
    Doseq( sym1, item, m, m), 'nil', 'none' )
    Doseq( sym2, item, 1, n-m, nul, 'none' )
```

## Eliminate separated open ranges

As a result of the above steps,
all ranges now have a minimum of exactly 1.

If we have
```
    Doseq( seq, item, 1, 'inf', sep, 'proper' )
```
we convert it to a left recursion, as follows
```
    seq ::= item
    seq ::= seq sep item
```

## Eliminate unseparated open ranges

If we have
```
    Doseq( seq, item, 1, 'inf', 'nil', 'none' )
```
we convert it to a left recursion, as follows
```
    seq ::= item
    seq ::= seq item
```

## Some definitions

As a result of the previous steps
all ranges are now closed.
(A closed range is one with an explicit maximum.)

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

## Eliminate large spans

As a reminder,
at this point all ranges are normalized --
that is, their minimum is 1.

If we have
```
    Doseq( seq, item, 1, n, sep, 'proper' )
```
where n is greater than 2,
we convert it into a choice of two
smaller ranges, as follows
```
    seq ::= sym1
    seq ::= sym2
    Doseq( sym1, item, 1, pow2(n), sep, sep_type )
    Doseq( sym2, item, 1, n-pow2(n), sep, sep_type )
```

## Eliminate spans

Since `Doseq()` is recursive,
the previous step will eliminate all spans
whose maximum is greater than 2.
So the only possible span at this point is
```
    Doseq( seq, item, 1, 2, sep, sep_type )
```
which we convert to a choice of blocks,
as follows:
```
    seq ::= sym1
    seq ::= sym2
    Doseq( sym1, item, 1, 1, sep, sep_type )
    Doseq( sym2, item, 2, 2, sep, sep_type )
```

With this step, we have eliminated all spans.
Only blocks remain to be converted
into BNF rules.

## Eliminate large blocks

If we have
```
    Doseq( seq, item, n, n, sep, 'proper' )
```
where n is 2 or more,
we convert it into a sequence of two
smaller blocks, as follows
```
    seq ::= sym1 sym2
    Doseq( sym1, item, pow2(n), pow2(n), sep, 'termination' )
    Doseq( sym2, item, n-pow2(n), n-pow2(n), sep, 'proper' )
```

If we have
```
    Doseq( seq, item, n, n, 'nil', 'none' )
```
where n is more than 2,
the conversion is
```
    seq ::= sym1 sym2
    Doseq( sym1, item, pow2(n), pow2(n), 'nil', 'none' )
    Doseq( sym2, item, n-pow2(n), n-pow2(n), 'nil', 'none' )
```

## Eliminate separated 2-blocks

Again,
since `Doseq()` is recursive,
the previous step converted all blocks to blocks
whose length is at most 2.

If we have
```
    Doseq( seq, item, 2, 2, sep, 'proper' )
```
we convert it to
```
    seq ::= item sep item
```

If we have
```
    Doseq( seq, item, 2, 2, 'nil', 'none' )
```
we convert it to
```
    seq ::= item item
```

## Eliminate all blocks

At this point the only 6-tuples left to
reduce to BNF rules,
are 1-blocks.

If we have
```
    Doseq( seq, item, 1, 1, sep, sep_type )
```
we convert it to
```
    seq ::= item
```

With this final step, we have reduced all sequence
rules to BNF rules.

### Implementation

## Avoid duplication of rules

## Memoize calls to `Doseq()`

Reductions of the 6-tuples should be memoized.
That is, for every call to `Doseq()`,
```
    Doseq( seq, item, 0, inf, sep, sep_type )
```
the algorithm should first look in the memoization
for the 5-tuple composed of the its last 5 elements
```
    [ item, 0, inf, sep, sep_type ]
```
If this 5-tuple is present in the memoization,
its value of the memoization
will be the value of `seq` for a previous call
of `Doseq()` with this 5-tuple.
The memoized value
value of `seq` of `seq` should be used
as the new value of `seq`,
and the steps of `Doseq()`
for that 5-tuple should not be re-run.

If the 5-tuple is not present,
the steps of `Doseq()`,
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
