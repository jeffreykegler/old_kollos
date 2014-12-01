# Kollos: sequence rule rewrite

This document describes how the LUIF rewrites
sequence rules.
In the following rule,
`Rep`, `Rep1`, `Rep2`, etc. are mortar symbols,
introduced to function
as left hand sides for intermediate rules.

Where separation or termination is relevant,
it is shown as the `% sep`, where it is understood
that the relevant separation or termination is
to be used.
If there is no separation or termination,
then the separation/termination specifier
is to be omitted.

These rewrite may call for rules with a mortar
LHS and the same
RHS and punctuation to be added
multiple times.
The rules added should be kept in table,
and, when a rule with a RHS and punctuation
identical to one already in the table would be
added,
instead the mortar LHS should be reused.

## Empty quantification

Rewrite `A**0..0` or `A**0` as
``
   Rep ::= -- empty rule
``

## '?' quantifier

Rewrite `A?` or `A**0..1` as two rules

``
   Rep ::= -- empty rule
   Rep ::= A -- singleton rule
``

Ignore any separators or terminators.

## Kleene star

Rewrite `A**0..*` as `A*`

Ignore any separators or terminators.

## Infinite quantifiers

For `A**N..* % sep` introduce the intermediate rules
``
   Rep ::= Rep1 sep Rep2
   Rep1 ::= A ** 0..N-1 % sep
   Rep2 ::= A+ % sep -- singleton rule
``
Note that because of the application of previous
rules, `N` here must be at least 2.
The rule for `Rep1` is subject to processing
in the steps which follow.

## Ranges with a minimum of zero

For `A**0..M % sep`,
introduce these new rules.
``
   Rep ::=  -- empty rule
   Rep ::= A ** 1 .. (M-1) % sep
``
Note that `M` will be at least one,
because of the application of previous rules.
These rules are subject to processing
in the steps which follow.

## Ranges with a minimum of two or more

For `A**N..M % sep`, where N is 2 or more,
introduce these new rules.
``
   Rep ::= Rep1 sep Rep2
   Rep1 ::= A ** N-1 % sep
   Rep2 ::= A ** 1 .. (M-N+1) % sep
``
These rules are subject to processing
in the steps which follow.

## One-based ranges

At this point,
because of the application of previous rules,
all ranges are either one-based or blocks.
(A block is a range of the form `A**N..N` --
its minimum and maximum are identical.

Let `pow2(X)` be the largest power of two
strictly less than `X`.
That is
```
    pow2(5) == 4
    pow2(7) == 4
    pow2(8) == 4
    pow2(9) == 8
```

Also previously, we did not
need to distinguish between separators
and terminators.
In this step we will have to.

We will first consider separators.
For a range of the form
For `A**1..M % sep`, where M is 5 or more,
rewrite as follows:
```
   Rep ::= A ** 1 .. (pow(M)-1) % sep
   Rep ::= Rep1
   Rep ::= Rep1 sep Rep2
   Rep1 ::= A ** pow(M) % sep
   Rep2 ::= 1 ** (M-pow(M)) % sep
   Rep ::= Rep1 sep Rep2
   Rep1 ::= A ** N-1 % sep
   Rep2 ::= A ** 1 .. (M-N+1) % sep
```




[ Lots and lots to be added here. ]

# Rewrite


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
