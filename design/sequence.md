# Kollos: sequence rule rewrite

This document describes how the LUIF rewrites
sequence rules.
In the following rule,
`Rep`, `Rep1`, `Rep2`, etc. are mortar symbols,
introduced to function
as left hand sides for intermediate rules.

Where punctuation
(separation or termination)
is relevant,
it is shown as the `% punct`, where it is understood
that the relevant separation or termination is
to be used.
It is understood that,
in cases where there is no punctuation,
the punctuation specifier
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

For `A**N..* % punct` introduce the intermediate rules
``
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** 0..N-1 % punct
   Rep2 ::= A+ % punct -- singleton rule
``
Note that because of the application of previous
rules, `N` here must be at least 2.
The rule for `Rep1` is subject to processing
in the steps which follow.

## Ranges with a minimum of zero

For `A**0..M % punct`,
introduce these new rules.
``
   Rep ::=  -- empty rule
   Rep ::= A ** 1 .. (M-1) % punct
``
Note that `M` will be at least one,
because of the application of previous rules.
These rules are subject to processing
in the steps which follow.

## Ranges with a minimum of two or more

For `A**N..M % punct`, where N is 2 or more,
introduce these new rules.
``
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** N-1 % punct
   Rep2 ::= A ** 1 .. (M-N+1) % punct
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
For `A**1..M % punct`, where M is 5 or more,
rewrite as follows:
```
   Rep ::= A ** 1 .. (pow(M)-1) % punct
   Rep ::= Rep1
   Rep1 ::= A ** pow(M) % punct
   Rep2 ::= Rep1 punct (A**1..(M-pow(M)) % punct)
```
The parentheses around the final repetition
in the rule for `Rep2`
are unnecessary, but are added
for clarity.

For terminators, we will need to add
a rule.
```
   Rep ::= A ** 1 .. (pow(M)-1) %% punct
   Rep ::= Rep1
   Rep ::= Rep1 punct
   Rep1 ::= A ** pow(M) %% punct
   Rep2 ::= Rep1 punct A ** 1..(M-pow(M)) %% punct
```

This step should be repeated until
all ranges are either blocks,
or have an maximum of four or less.

## Short ranges

Ranges of 4 or less should be turned
into a sets of fixed length alernatives.
For example `A**1..4` should
be rewritten as
```
    Rep ::= A
    Rep ::= A punct
    Rep ::= A punct A
    Rep ::= A punct A punct
    Rep ::= A punct A punct A
    Rep ::= A punct A punct A punct
    Rep ::= A punct A punct A punct A
    Rep ::= A punct A punct A punct A punct
```
where `punct` is the punctuator.
It the punctuator is separator,
the rules ending in `punct` should be ommitted.

# Large blocks

The only remaining ranges are now blocks,
that is,
they have the same minimum and maximum,
and so are of the form `A**N..N`
or simply `A**N`.
If N is greater than 4,
we binarize the block, much as we did with
ranges.

Again, we need to distinguish separation
from termination.
For the termination case,
`A**1..M %% punct`, where M is 5 or more,
rewrite as follows:
```
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** pow(M) % punct
   Rep2 ::= A ** 1..(M-pow(M)) %% punct
```
Note the `Rep1` rule uses separation,
while the `Rep2` rule uses termination.

For the separation case, we use separation
for both the `Rep1` and `Rep2` rules:
```
   Rep ::= Rep1 punct Rep2
   Rep1 ::= A ** pow(M) % punct
   Rep2 ::= A ** 1..(M-pow(M)) % punct
```

This step should be repeated until
all ranges are blocks,
and have a maximum of four or less.

## Short blocks

Blocks of 4 or less should be turned
into a BNF rule.
For example `A**4` should
be rewritten as
```
    Rep ::= A punct A punct A punct A
    Rep ::= A punct A punct A punct A punct
```
where `punct` is the punctuator.
It the punctuator is separator,
the rule ending in `punct` should be ommitted.

## Eliminate terminators

At this point, we have no more ranges or blocks --
they have all been rewritten into

+_regular BNF rules;
+ empty rules;
+ star-quantified (`*`) rules;
+ plus-quantified (`+`) rules;

We do one more rewrite.
Libmarpa will handle terminators,
but we want to move the rewrites
out of the Libmarpa core code,
and this is a good place to start.
For a repetition of the form `A* %% punct`,
we turn the punctation is separation,
using these two rules:
```
   Rep ::= A* % punct
   Rep ::= (A* % punct) punct
```
The parentheses in the second rule are
not necessary, but are added for clarity.

## Libmarpa

We've now rewritten all repetitions into
a form in which a Libmarpa grammar can
be created from them.

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
