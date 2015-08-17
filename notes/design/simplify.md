# Libmarpa: Planned simplifications

This document describes some simplifications
that I plan for Libmarpa, the core C library
implementing the Marpa parser.
Many of these are based on the idea of taking
things now done inside Libmarpa, particularly
grammar rewrites, and doing them in an outer
layer.
For that reason, these plans are very much
related to the Kollos project.

## Eliminate internal/external symbol levels

In the SLIF, there are 3 levels of symbols

+ Perl interface level symbols and rules
+ Libmarpa external
+ Libmarpa internal

In other words, there are two levels of "external"
symbol, one inside Libmarpa, and one in the layer
above it.
In Kollos, I want to move all the "external" symbol
logic out of Libmarpa, so that inside Libmarpa
there are only internal rules and symbols.
Clearly, this will make Libmarpa simpler.

## New evaluator

I want to take the current ASF logic,
as currently implemented for the SLIF in Perl,
rewrite it in C, and move it into Libmarpa.
There it would create ASF "glades"
directly from the recognizer's tables,
replacing the current bocage.

The new evaluation logic would be both 
more powerful and simpler.
Eliminated in favor of ASF's would be four
other objects:
the bocage, ordering, tree and valuator objects.

## Events

Currently Libmarpa support events for predictions,
nulling symbols and completions.
All of these are special cases of dot position within
a rule.
Libmarpa would be both simpler and more powerful,
if events were defined at a lower level --
by rule and dot location.
The current events could be implemented in
Kollos, in terms of the low-level dot-location events.

## Eliminate support nulling symbols

Rewrites within Libmarpa currently eliminate properly
nullable symbols, leaving only non-nulling symbols,
and nulling symbols.
In fact, Libmarpa can go one step further.
The nulling symbols can also be rewritten out
of the grammar --
the nulling symbols can be removed from all rules, and
their location recorded.
After the parse the recorded locations can be
used to restore the nulling symbols.

## Eliminate support for cycles

Libmarpa supports cycles.
Since Libmarpa is intended as a practical parser,
the infinite recursion of cycles is only
"supported" in a special sense.
Rules which cause cycles also allow
non-cycling parses.
In the presence of rules and symbols which cycle,
Libmarpa produces all,
and only those parses which do *not*
cycle.

It would be possible to also allow those parses
which cycle only a finite number of times,
but there seems to be no demand for this --
there's very little demand, in fact,
for Marpa's current level of support for cycles.

Currently Libmarpa tests for cycles in many places,
and has special case code to deal with cycles.
With Kollos, I plan to move the cycle-handling into
the grammar rewrite.
Those rules which both allow cycles and 
non-cyclical parses will be rewritten
so that they only allow non-cycling parses.
Rules which only allow cycling parses will
be eliminated.

With the grammar rewrite in place,
a lot of complex and mysterious
code can simply be removed from
Libmarpa.

## Eliminate the "unvalued symbols" feature

Libmarpa currently implements "unvalued symbols" --
tokens which the lexer can specify as having an "undefined"
value.
The intent here was to allow optimization at evalution time.
This optimization was targeted at situations where evaluation
would be by expensive callbacks.
It turned out to introduce a lot of complications,
and to have little or no payoff.

<!---
vim: expandtab shiftwidth=4
-->
