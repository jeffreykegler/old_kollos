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
   A ->* A middle A,
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

