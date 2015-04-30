# When in Marpa linear?

This contains some theoretical notes
on the grammars for which Marpa is linear.
These notes are very rough and preliminary,
and not intended to be understand by anyone
but Jeffrey.

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

