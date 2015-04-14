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
    must be between symbols and only between
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
We do not need to define
`pow2(1)`
or `pow2(0)`.

## Chomsky form

Readers will note that the rewrite below
leaves the rule in a form where no RHS is longer
than 2 symbols.
Libmarpa's internal form will eventually be
converted to this "Chomsky form".
Conversion to Chomsky form during this
rewrite is not necessary --
it would happen anyway at a later stage --
but doing it here results in a more
natural grammar.

## Describing the rewrite

The rewrite will be a recursive function,
which we will call, `Doseq()`, so that
```
    Doseq( seq, item, 0, inf, sep, sep_type )
```
produces the rewrite for one or our 6-tuples.
In the rewrite, one or more new symbols will
be introduced.
One of these will be `top`,
and the others will be of the form
`sym1`, `sym2`, etc.
In the actual rewrite, their names
must always be such
that those names are
unique to that step of the rewrite.
The symbol called `top`
will be
the LHS of the "highest level"
rule in that stage of the
rewrite.
The `top` symbol is the return value of
`Doseq()`.

The algorithm must track
the current rules,
so that no rule is ever added
more than once.

### Eliminate liberal separation

If we have
```
    Doseq( seq, item, m, n, sep, 'liberal' )
```
we convert it into
```
    top ::= sym1
    top ::= sym2
    sym1 ::= sym2 sep
    Doseq( sym2, item, m, n, sep, 'proper' )
```
where `sym1`, `sym2` and `sym3` are new symbols.

### Eliminate termination

If we have
```
    Doseq( seq, item, m, n, sep, 'terminator' )
```
we convert it into
```
    top ::= sym1 sep
    Doseq( sym1, item, m, n, sep, 'proper' )
```
where `top`, and `sym1` are new symbols.

For the rest of this procedure, we can assume
that separation is either `proper` or `none`.

### Eliminate nullables

If we have
```
    Doseq( seq, item, 0, n, sep, seq_type )
```
we convert it into
```
    top ::= 
    top ::= sym1
    Doseq( sym1, item, 1, n, sep, 'proper' )
```

We may now assume that the minimum of our
6-tuple is at least 1.

## Normalize separated open ranges

By an "open range", we mean one where the maximum
is `inf`.

If we have
```
    Doseq( seq, item, m, 'inf', sep, 'proper' )
```
where m is 2 or more, we convert it to
we convert it into
```
    top ::= sym1 sym2
    sym2 ::= sep sym3
    Doseq( sym1, item, 1, (m-1), sep, 'proper' )
    Doseq( sym3, item, 1, n, sep, 'proper' )
```

## Normalize unseparated open ranges

If we have
```
    Doseq( seq, item, m, 'inf', nil, 'none' )
```
where m is 2 or more, we convert it to
we convert it into
```
    top ::= sym1 sym2
    Doseq( sym1, item, 1, (m-1), nil, 'none' )
    Doseq( sym2, item, 1, n, nul, 'none' )
```

## Eliminate separated open ranges

As a result of the above steps,
all open ranges now have a minimum of exactly 1.

If we have
```
    Doseq( seq, item, 1, 'inf', sep, 'proper' )
```
we convert it to a left recursion, as follows
```
    top ::= item
    top ::= top sym1
    sym1 ::= sep item
```

## Eliminate unseparated open ranges

If we have
```
    Doseq( seq, item, 1, 'inf', nil, 'none' )
```
we convert it to a left recursion, as follows
```
    top ::= item
    top ::= top item
```

As a result of the previous steps
all ranges are now closed.
(A closed range is one with an explicit maximum.)

## Some definitions

In what follows, we'll need some definitions:

+ The *span* of the closed range `A ** N..M` is `(M-N)+1`.

* A block is a closed range with a span of one, for example,
`A**42`.

## Closed ranges with a minimum of two or more

Rewrite them so all ranges are either blocks or 1-based.
For `A**N..M % punct`, where N is 2 or more,
introduce these new rules.
```
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** N-1 % punct
   Rep2 ::= A ** 1 .. (M-N+1) % punct
```

## One-based non-block ranges

At this point,
all ranges are either one-based or blocks.

For a range of the form
For `A**1..M % punct`, where M is 5 or more,
rewrite as follows:
```
   Rep ::= A ** 1 .. (pow(M)-1) % punct
   Rep ::= Rep1
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** pow(M) % punct
   Rep2 ::= A**1..(M-pow(M)) % punct
```

This step should be repeated until
all ranges are either blocks,
or have an span of four or less.

## Short one-based ranges

Ranges of 4 or less should be turned
into a sets of fixed length alernatives.
For example `A**1..4 % punct` should
be rewritten as
```
    Rep ::= A
    Rep ::= A punct A
    Rep ::= A punct A punct A
    Rep ::= A punct A punct A punct A
```

# Large blocks

The only remaining ranges are now blocks,
that is,
they have the same minimum and maximum,
and so are of the form `A**N..N % punct`
or simply `A**N % punct`.
If N is greater than 4,
we binarize the block, much as we did with
ranges:
```
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** pow(M) % punct
   Rep2 ::= A ** 1..(M-pow(M)) % punct
```

This step should be repeated until
all ranges are blocks,
and have a maximum of four or less.

## Small blocks

Blocks of 4 or less should be turned
into a single NF rule.
For example, `A**4 % punct` should
be rewritten as
```
    Rep ::= A punct A punct A punct A
```

<!---
vim: expandtab shiftwidth=4
-->
