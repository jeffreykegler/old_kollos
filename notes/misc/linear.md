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

Definition: A recursion is double ended
if it is both a left and a right recursion.
Such a recursion may be indirect.

Theorem:
Let `g` be an unambiguous grammar.
It contains no double-ended recursions.

Proof:
Assume for a reductio that
A is a double-recursive symbols in `g`.
Then there is a derivation
```
   A ->* A middle A,
```
where `middle` is a sentential form
which may be empty.

The symbol `A`
derives the sentential form
```
   A middle A middle A
```
in two different ways,
and therefore A is an ambiguous symbol.
Any grammar containing is
therefore ambiguous,
which is contrary to assumption for
the theorem.
QED.

