# Kollos: precedenced rule rewrite

This document describes how the KHIL rewrites
precedenced rules for the KIR.
Kollos's precedenced rules are what are called
in Marpa::R2 "prioritized rules".
The change in names is because
the term "priority" is already heavily overloaded in
the Marpa context, and in general.

It is assumed the reader is familiar with Marpa::R2's
prioritized rules.
A reader who is rusty should glance at one of the
examples in the Marpa::R2 synopses.

In this document we will ignore actions and adverbs.
Without those,
a precedenced rule, consists of a LHS,
and two or more RHS alternatives.
At least two of these RHS alternatives should be
at different precedences.
If all the RHS alternatives are at a single
the rule, from the point of view of this document,
should be treated as a special case.
The rewrite outlined in this document should *not*
be applied to a rule, if all of its alternatives
are at a single precedence.

## Numbering the precedences

In the Marpa::R2, the precedenced ("prioritized")
rules list precedences, from tightest to loosest,
separated by double bar
operators (`||`).
Within precedences, RHS alternatives are separated
by the single bar operator (`|`).

Readers who want to be reminded of how a precedence
scheme works should look at the perlop man page.
In this document what is traditionally called "highest"
priority is called the "tightest",
and what is traditionally called the "lowest" priority
is called "loosest" priority.

In the perlop man page, the priorities (as they are
called on that page) are numbered from
"highest" to "lowest", with 0 being the highest,
so that the lowest priority is the highest-numbered.
That kind of confusion is common in the literature,
which is why I have preferred the terms "tight" and
"loose" over "high" and "low".

In this document,
the loosest priority,
traditonally called the lowest,
will be priority 0.
Priorities will be non-negative numbers,
so that the loosest and traditionally lowest priority
and will also
be the lowest priority numerically.
The tightest priority,
traditionally called the highest,
will be the highest-numbered.

In what follows, we will call the number
of the tightest precedence `tightest`.
The number of the loosest precedence will
be called `loosest`.
`loosest` will always be 0.

If `x` is a precedence,
```
    looser(x) == x-1 if x > 0
    looser(0) == 0
    tighter(x) == x+1 if x < tightest
    tighter(tightest) == tightest
```
Intuitively,
`looser(x)` and `tighter(x)` are
used for stepping up and down the
precedences.
`looser(x)` is the
next-loosest predenence,
and `tighter(x)` is the
next-tightest predenence.

## Rewriting precedenced rules

### Preparing the work list

In a first pass over a precedenced rule,
we produce a work list
of RHS alternatives, with their numerical precedence.
Precedences should be numbered from loosest
to tightest, as described above.
If we stick to the SLIF's convention,
which is also the traditional one,
this means the numerical
order of the precedences
will be the reverse of their lexical order.

In the work list,
we also record the associativity of each RHS
alternative.
This associativity may be `right`, `left` or `group`.
We have been ignoring the adverbs, or options,
but this is a case where they are relevant --
the adverbs may specify associativity.
By default, associativity is `left`.

### The top level rule

In what follows, `exp` will represent the LHS symbol
of the precedenced rule.
We will need to have a unique symbols for 
`exp` at each level of precedence.
We will represent the symbol for `exp`
at level `x` as `exp[x]`.

The top level rule for the precedenced rule
will be a rule with the precedenced rule's LHS
as its LHS,
and the unique symbol for the lowest precedence
as its RHS.
That is, the top level rule will be
```
     exp ::= exp[0]
```

### The "spine"

In many expressions, there is no logic at a given
precedence level, so that we need to simply "fall through"
to the next-tighter (or next-higher) level of precedence.
Therefore, for every precedence `x`, such
that `x` is less than `tightest`, we
add the rule
```
   exp[x] ::= exp[tighter(x)]
```
For example, if the precedence ran from
`loosest == 0` to `tightest == 4`,
we would all the rules
```
    exp[0] ::= exp[1]
    exp[1] ::= exp[2]
    exp[2] ::= exp[3]
    exp[3] ::= exp[4]
```

### Left association

We now can deal with the RHS alternatives in the work list.
Let `curr` be the precedence of the RHS alternative.
If a RHS alternative has left association, the default,
we rewrite the RHS, replacing all occurrences of `exp`.
We replace the leftmost occurrence of `exp` with `exp[curr]`,
and the others with `exp[tighter(curr)]`.
We then add a rule with the rewritten RHS,
and `exp[curr]` as the LHS.

For example, if the RHS alternative is
```
    exp + exp
```
we add the rule
```
    exp[curr] ::= exp[curr] + exp[tighter(curr)]
```

Note that `exp` may not occur on the RHS, in which
case no RHS replacements will be necessary.

### Right association

Right association is handled in a way that is
symmetric with left association.
Again, let `curr` be the precedence of the RHS alternative.
If a RHS alternative has right association,
we rewrite the RHS, replacing all occurrences of `exp`.
We replace the *rightmost* occurrence of `exp` with `exp[curr]`,
and the others with `exp[tighter(curr)]`.
We then add a rule with the rewritten RHS,
and `exp[curr]` as the LHS.

For example, if the RHS alternative is
```
    exp ** exp
```
we add the rule
```
    exp[curr] ::= exp[tighter(curr)] ** exp[curr]
```

### Group association

The archetypal case for
group association is the parenthesis operator.
Intuitively, group association allows any expression
to occur inside another "surrounding" expression.
In the case of the parentheses, of course,
they actually surround their contents lexically.

Let `curr` be the precedence of the RHS alternative.
If a RHS alternative has group association,
we rewrite the RHS, replacing all occurrences of `exp`
with `exp[0]`,
We then add a rule with the rewritten RHS,
and `exp[curr]` as the LHS.

For example, if the RHS alternative is
```
    ( exp )
```
we add the rule
```
    exp[curr] ::= ( exp[0] )
```

<!---
vim: expandtab shiftwidth=4
-->
