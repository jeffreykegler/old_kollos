# Kollos: sequence rule rewrite

This document describes how the LUIF rewrites
sequence rules.
In the following rule,
`Rep`, `Rep1`, `Rep2`, etc. are mortar symbols,
introduced to function
as left hand sides for intermediate rules.

This rewrite may call for rules with a mortar
LHS and the same
RHS and punctuation to be added
multiple times.
The rules added should be kept in table,
and, when a rule with a RHS and punctuation
identical to one already in the table would be
added,
the rule in the table should be reused instead.

## Eliminate terminators

If any rule has a terminator,
rewrite it as two rules with separation,
one terminated, and one not.
For example, rewrite
```
    A ** 42..1041 %% punct
```
as `Rep`, and add these two rules:
```
    Rep ::= A ** 42..1041 % punct
    Rep ::= (A ** 42..1041 % punct) punct
```

In the second rule of the example,
unnecessary parentheses have been added.
In what follows,
we will often over-parenthesize for clarity.

In the rest of this document, most examples
will be punctuated with separation.
From these, it should be easy to
deduce how the rewrite is done
in the unpunctuated case.

## Eliminate '?' quantifier

Rewrite `A?` or `A**0..1` as two rules
```
   Rep ::= -- empty rule
   Rep ::= A -- singleton rule
```

Ignore any separator.

## Eliminate explicitly-based open ranges

An explicitly based open range is a repetition
of the form `A ** N..* % punct`.

+ Rewrite `A ** 0..* % punct` as `A* % punct`.

+ Rewrite `A ** 1..* % punct` as `A+ % punct`.

* Where N is 2 or more,
  rewrite `A ** N..* % punct` as
  as
```
    Rep ::= Rep1 punct Rep2
    Rep1 ::= (A ** 1 .. N-1 % punct)
    Rep2 ::= A+
```

## Closed ranges with a minimum of zero

All ranges are now closed -- they have an explicit maximum.
Rewrite `A**0..0` or `A**0` as
```
   Rep ::= -- empty rule
```
For `A**0..M % punct`, where M is 1 or more.
introduce these new rules.
```
   Rep ::=  -- empty rule
   Rep ::= A ** 1 .. (M-1) % punct
```

## Closed ranges with a minimum of two or more

Rewrite them so all ranges are either

+ blocks, that is, the minimum and maximum the same; or
+ 1-based.

For `A**N..M % punct`, where N is 2 or more,
introduce these new rules.
```
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** N-1 % punct
   Rep2 ::= A ** 1 .. (M-N+1) % punct
```

## Some definitions

In what follows, we'll need some definitions:

+ The *span* of the closed range `A ** N..M` is `(M-N)+1`.

* A block is a closed range with a span of one, for example,
`A**42`.

* A *trivial range* is a range with a span of zero or one.

* `pow2(X)` is the largest power of two
strictly less than `X`.
That is
```
    pow2(5) == 4
    pow2(7) == 4
    pow2(8) == 4
    pow2(9) == 8
```

## One-based non-block ranges

At this point,
all ranges are either one-based or blocks.

We will first consider separators.
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
For example `A**4 % punct` should
be rewritten as
```
    Rep ::= A punct A punct A punct A
```

## Pass to Libmarpa

At this point, we have no more ranges or blocks --
they have all been rewritten into

+_regular BNF rules;
+ empty rules;
+ star-quantified (`*`) rules;
+ plus-quantified (`+`) rules;

All repetitions are now in
a form in which a Libmarpa grammar can
be created from them.

# Other approaches

A naive approach to
a rewrite of rules of the form `A ::= B{min,max}`
would rewrite `A ::= B{42,1041}` into
1000 BNF rules.
We will try to do better than this,
with a binarized approach.
There is
[a Perl script in a Github
gist](https://gist.github.com/jeffreykegler/2324781#file-minmax_to_bnf-pl)
implementing an algorithm for doing this.

<!---
vim: expandtab shiftwidth=4
-->
