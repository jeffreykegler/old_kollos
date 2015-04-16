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

In the perlop man page, the priority are numbered from
"highest" to "lowest", with 0 being the highest,
so that the lowest prioriity is the highest-numbered.
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

## Rewriting precedenced rules

### Preparing the work list the precedence levels

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

<!---
vim: expandtab shiftwidth=4
-->
