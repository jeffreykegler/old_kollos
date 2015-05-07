# When in Marpa linear?

This contains some theoretical notes
on the grammars for which Marpa is linear.
These notes are very rough and preliminary,
and not intended to be understand by anyone
but Jeffrey.

## Right recursions

A right recursion is a non-trivial sequence of derivations,
in which the the rightmost symbol of the first step
of the sequence is also the rightmost symbol of the
last step.

A right recursion derivation
step is a single step in a right recursion
which replaces the rightmost symbol,
call it `A`,
with `rhs`
where `A ::= rhs` must be a rule in `g`.
`A ::= rhs` is said to have been "used"
in the right recursive derivation step.
If a rule is used in a right recursive
derivation step,
it is called a right recursive rule.

A right recursion is *marked* if and only if
the only Earley set in an Earley parse where
it adds completions is the set built when
scanning its last symbol.

A right recursion is *Leo-memoable*
at a location,
or *memoable*,
if one of its recursion symbols
ends at that location,
and would produces a completion in the Earley set
at that location.
A right recursion is *fully memoable* if and only if
it is memoable at the location of all of its recursion
symbols.

A right recursion is *Leo-memoized*, or *memoized*,
at a location,
is if is Leo-memoable,
and the right recursion symbol is unique,
in the sense that it occurs as the postdot
symbol of exactly one Earley item.

A "skip" in a Leo-memoization is a location
which is Leo-memoable, but which is not
Leo-memoized.
A "skip sequence" is a set of consecutive
right recursion parse locations
which are all skips.

Theorem:
A right recursion is either marked or fully
memoable.

Proof:

Assume for a reductio that,
in an unmarked right recursion,
there is a right recursion location,
call it `L`,
and `L` is not memoable.
By assumption for the reduction,
`L` is a right recursive location,
so that there is a right recursive symbol,
call it `RR`,
ending at `L`.
The right recursion must occur in the Earley
parse,
and therefore so must all of its right recursive
symbols.
So there must be a completion for `RR` at `L`.
Therefore `L` is memoable, contrary to assumption
for the reductio.
Hence all locations `L` are memoable,
and the right recursion is fully memoable.
QED.

[ Note: the fact that the right recursion is unmarked
is really not used in the above proof.
This should be cleaned up. ]

At a skip, the right recursive completions
are added as far back as the beginning of
the right recursion,
or as the most recent Leo memoization
whichever is encountered first.

[ Demonstrate in more detail that
the creation of completions stops
when the first Leo item is encountered? ].

The number of completions add for a unmarked
right recursion is as follows:

* For the first right recursive symbol, 1 completion.

* For the right recursive symbol symbols after the first,

   - If the preceding location was not a skip, 2 completions.

   - If the preceding `n` locations, where `n` is greater than 0,
     were skips, `n + 1` completions.

## Amortization of marked right recursions

[ How to do this? ]

## Unambiguous Right Recursions

In an unambiguous grammar,
every right recursive symbol produces,
for a specific sentence,
a unique set
of transition symbols, factored uniquely.

Proof:
The proof is by reduction to absurdity.
Call the sentence `x`.
Suppose a right recursion,
from one of its right-recursive
symbols, `RR`
produced more than
one set of transition symbols,
or that
the set it produced could be factored differently.
There would be two derivation trees from `RR`
of `x`,
so that `RR` would be an ambiguous symbol.
Since `RR` is an ambiguous symbol.
and any grammar containing `RR` would be
ambiguous,
which is contrary to assumption for the theorem.
QED.

## Double Ended Recursions

Definition: A derivation is a double ended
recursion
if it is both a left and a right recursion.
That is, if it is
```
    A =>* A middle A
```
where `middle` if a sentential
form which may be empty or contain
other instances of `A`.

Theorem:
If a grammar is unambiguous,
it does not allow a double-ended recursion.

Proof:
Assume for a reductio that
grammar `g` is unambiguous, but that for some input
it contains, `Deriv`,
the derivation
```
   A ->+ A middle A,
```

We can derive the sentential form
```
   A middle A middle A
```
by expanding either the rightmost or
leftmost A in `Deriv`.
In the first case the tree has the form
```
A(A middle (A middle A))
```
and in the second
case it is
```
A((A middle A) middle A)
```
These are two different derivation trees,
so that A is an ambiguous symbol.
Since grammar `g` contains `A`,
an ambiguous symbol,
`g` is ambiguous.
But `g` was assumed to be unambiguous
for the reductio.
This show the reductio.
QED.

## No Ambi-recursive symbols in unambiguous grammars.

Definition: A symbol is ambi-recursive
if it allows the two derivations
```
    A =>+ A after
    A =>+ before A
```
where `before` and `after`
are sentential
forms which must be non-empty,
but which may contain
other instances of `A`.

Theorem:
If a grammar is unambiguous,
it has no ambi-recursive symbols.

Proof:
Assume for a reductio that
grammar `g` is unambiguous, but that for some
symbol `A`
we have the two derivatsions,
```
   A ->+ A after, and
   A ->+ before A, and
```
where `after` and `before` are non-empty.

We can derive the sentential form
```
   before A after
```
in two ways, as
```
   D1: A ->+ A after ->+ before A after, and as
   D2: A ->+ before A ->+ before A after
```

We have three cases:

* "After first": The derivation step `A after` comes first.

* "Before first": The derivation step `before A` comes first.

* "Before equals after": `before A == A after`.

We first show that the "Before equals after" case is
impossible, using a reductio.
For the reductio,
we assume that `D1 == D2`.
If `before A == A after`, since both `before` and
`after` are non-empty, we must have that
```
   Eq-1: before A == A after == A middle A
```
where middle is a sentential form which may
contain another instance of `A`,
and which may be empty.
But if `Eq-1` is true,
then
```
   A ->+ A middle A,
```
which is a double-ended recursion,
so that A must be an ambiguous symbol.
If `A` is ambiguous, then `g` is ambiguous
contrary to assumption for the outer
reductio.
This show the inner reductio,
and that the "Before equals after" case
is false.

For the remaining two cases,
the derivation trees have the forms
```
    A(before A(A after)), and
    A(A(before A) after)
```
Since `before A != A after`,
these are two different derivation trees,
so that A is an ambiguous symbol.
Since grammar `g` contains `A`,
an ambiguous symbol,
`g` is ambiguous.
But `g` was assumed to be unambiguous
for the outer reductio.
This shows the outer reductio
and the theorem.
QED.

## Two eruptions, one right signature

Theorem:
If two distinct eruptions are distinct,
then they are part of distinct derivation
trees.

Proof:
We first show that two eruptions
are distinct,
the derivation trees in which they occur
must be distinct.
Assume for a reductio that two
eruptions share the same derivation
tree.
They must also share the same chamber.
We follow the eruption
from its chamber.
If the eruptions are distinct,
or some node of the eruption will have
two up-paths.
But, an eruption is a derivation path,
so that this is not possible.
The shows the reductio,
and the theorem.
QED.

Theorem:
If two distinct eruptions over a sentence,
call it `seen`,
have one right signature,
call it `r-sig`,
then the grammar is ambiguous.

Proof:
Since all the symbols `r-sig`
in `r-sig` are productive, it
derives a sentence,
call it `unseen`.
The sentence `seen . unseen` is derived
from derivation trees containing both eruptions.
Since the two eruptions are distinct,
they occur in distinct derivation trees.
By the definition of ambiguous, then,
the grammar which they share is ambiguous.
QED.

## Middle recursion subsumption

The Middle Recursion Subsumption Theorem:
If `M` is a middle recursive symbol and
```
   1) M =>* pre1 A post1`
```
and
```
   2) A =>* pre2 M post2`,
```
then `A` is a middle recursive symbol.

Proof:
`M` is middle recursive so by the
definition of middle recursion
```
    3) M =>* pre3 M post4
    4) |pre3| > 0
    5) |post3| > 0
    6) M =>* pre3 pre1 A post1 post3 ; by eq. 1, 3
    7) A =>* pre2 pre3 pre1 A post1 post3 post2
         by eq. 2, 6
    8) |pre2 pre3 pre1| > 0 by eq. 4
    9) |post2 post3 post1| > 0 by eq. 5
```
From the definition of middle recursion and
eq. 7, 8 and 9, we have that `A` is a middle
recursive symbol.
QED.

## Descending an eruption

We define an *eruption sequence*
as a sequence of dotted rules,
where

* no rule occurs twice; and

* no dotted rule is a prediction.

As a reminder, there are no empty rules in `g`.

An eruption sequence
is of length at most `#rules`.
the number of rules in `g`.
Since `#rules` is finite,
The number of eruption sequences in `g`
is at most
`(#rules)! * (max-rhs*#rules)`,
where `max-rhs` is the maximum length of the
RHS of a rule in `g`.

We now consider a descent of the eruption,
starting from the top of the plume.
Since `g` is augmented,
this must be the RHS of the start rule,
starting at location 0 and ending at
location |w|.

In descending,
at each step of the eruption we must

* choose a dot position; this is called a
  *dot choicepoint*.

* choose a start location; this is called a
  *start choicepoint*.

* choose a rule; this is called a
  *rule choicepoint*.

Let

* `lhs` be the symbol before the dot
of the dot choicepoint,

* `start` be the location selected at the
  start choicepoint; and

* `rhs` be the sequence of symbols that is the
  RHS of the rule chosen at the rule choicepoint.

In that case, the next step of the eruption begin
at location `start` and contains the sequence of symbols
`rhs`.
`lhs ::= rhs` must be a rule in `g`.
and `start` must be
at or before the start of the chamber of
the eruption.

We use the eruption sequence to constraint
our choices.
The first occurence of each rule at a rule choicepoint
in the descent
must follow the eruption sequence.
The choice at the dot choicepoint which preceeds
a rule choicepoint must be to place the dot
at the position of the dot in the
same rule in the eruption sequence.

We call a choicepoint trivial iff there is
only one alternative to choose from at
that choicepoint.
We call a choicepoint non-trivial iff it is
not trivial.

We now study the form that the first non-trivial
choicepoint must take for the unfraught grammar `g`.

## ???

As a reminder,
a rule is recursive if is used in
a recursive step of a recursive
derivation.
Otherwise the rule is non-recursive.

### Different factorings

### Two non-recursive rules

If a rule is non-recursive it will
only occur once in the eruption,
so both rules must occur as indicated
in the rule sequence.
They therefore must be the same rule.

Suppose, for a reductio, that the
step factors the span of the 
eruption step differently.

### Two recursive rules, of different kinds

### Two middle-recursive rules

### A recursive and a non-recursive rule

### A left-recursive and a right-recursive rule

### Remaining choices

Summarizing the preceding steps,
the first ambiguous step in a descent
of a plume must
be

* a choice between two left-recursions; or

* a choice between two right-recursions.

