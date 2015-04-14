# Kollos: the intermediate representation

## Overview

Kollos's interface language will be the LUIF, essentially
Lua 5.1 extended with BNF.
A top layer, called the Kollos high layer, or KHIL,
will parse this into the "Kollos intermediate representation".
The Kollos intermediate representation,
also called the KIR,
is pure Lua 5.1 with some calls to the kollos Lua package.

Since the KIR is pure Lua 5.1, it can be run with Lua.
The KIR calls in the kollos package,
which at this point Jeffrey expects that he will write,
will then do lower level transformations to make the grammar
ready for Libmarpa.
These lower level transformations are called the Kollos lower
layer, or KLOL.

This document describes

* the "kollos" Lua package calls in the KIR.

* the KHIL "callbacks", which allow the KLOL to get information
  from the KHIL for error messages, tracing, debugging, etc.

## Motivation

An important reason for the KIR is to allow the LUIF to be
self-describing and self-generating.
This will be quite possible in theory,
the circular dependency has the potential
to make
maintenance and debugging so difficult
that self-generation
is not a wise to do in practice.
The solution is to have the self-generation take place
through an intermediate language.
In a pinch,
self-generation can be bypassed
by editing the KIR directly.

## The Kollos higher layer

The basic transformation needed to obtain the KIR from the LUIF is
translation of the LUIF rules, which may include precedenced and
sequence rules, into a form which allows only BNF rules.
In separate documents.
Jeffrey will describe the transformations necessary to translate from
precedenced rules to BNF rules,
and from sequence rules to BNF rules.

## Symbols, alternatives, and rules

The KHIL will find *external* rules, alternatives and symbols
in the LUIF,
which it will turn into *internal* rules and symbols.
The external rules are the sequence, precedenced and
BNF rules in the LUIF, one per statement.

An *alternative* is a part of
an external rule consisting of
a single LHS and a single RHS.
Internal rules do not have alternatives.
An ordinary BNF external rule
contains a single alternative.
An external sequence rule also contains only one alternative.
Precedenced external rules,
however, may contain many alternatives.
In the SLIF, the alternatives of precedenced
statements were separated by the bar (`|`)
and double bar (`||`) symbols.

Internal symbols are either *brick* symbols or *mortar*
symbols.
Every brick symbol has a corresponding external symbol.
A mortar symbol does not have
a corresponding external symbol.

As of this writing, Jeffrey is undecided whether rules, alternatives
and symbols should represented as integers or strings.
If strings, the representation for external symbols should
clearly be their lexical equivalent in the LUIF,
but the format of the others is also undecided.

The motivation of the above will, we hope,
be clearer when we outline the
transformations the KHIL must perform.

## KIR calls

The KIR will be Lua 5.1, and will assume that there is a "kollos.kir"
package with the calls listed in this section.
The examples assume that the Lua statement
```
    local kir = kollos.kir
```
has already been executed.

### Grammar constructor

```
     g = kir.grammar(start)
```
Constructs and returns a grammar.
`start` is declared to be an internal symbol,
and the start symbol of the grammar.
The grammar `g` is returned.
The grammar is an opaque object,
only to be used in other KIR
calls.

### Symbol declarators
```
    kir.terminal(sym1)
    kir.medial(sym2)
```
Internal symbols need to be declared before they
are used in a KIR rule.
These two calls declare `sym1` to be a terminal
symbol and `sym2` to be a medial symbol.
(A symbol is medial if and only if
it is not the start symbol and not a terminal).

### Rule declarators

```
    kir.rule(g, id, xid, options, lhs, rhs1, rhs2)
```
The
`kir.rule()` statement
declares a rule for grammar `g`.
The ID of the internal rule is `id`.
The ID of the external alternative is `xid`.
`options` is either a table of options,
or `nil`,
Its LHS is `lhs`.
Its RHS symbols are `rhs1` and `rhs2`.
The number of RHS symbols may vary from 0 on up.

As we will see when Jeffrey describes the
grammar rewrites, alternatives
may be broken up into many internal rules.
Of the rules into which an alternative is broken up,
one and only one will be the "top" rule.
Only the top rule of an alternative will have a semantics
associated with it.

The `options` argument must be defined if and only if
the rule being declared is a top rule.
If `options` is defined, it must be a table.
If one of its keys is `action`,
it specifies the action of the rule.
The action may represent a built-in action,
or may be a LUA function.
Details of the built-in action are left unspecified,
for the moment.

### Compile grammar
```
    kir.compile(g)
```
This compiles the grammar `g` into a form ready for
parsing.
This call may be unnecessary  --
it may be better to simply have the KLOL attach
a postamble to the KIR to implement the "compilation"
of the grammar.

## Callbacks to the KHIL

The KIR calls pass sufficient information down to the
KLOL for normal processing.
However, for error messages, debugging, etc.,
the KLOL needs to have more information available.

As a first guess,
the KHIL needs to make available the callbacks listed
in this section.
The examples assume that the Lua statement
```
    local khil = kollos.khil
```
has already been executed.

### Internal symbol accessors

```
    khil.provenance(isym)
```
Given an internal symbol `isym`, returns its
provenance.
The provenance is a history of the steps by
which this internal symbol was created.
Brick symbols, if they correspond exactly to external
symbols, may have a provenance of
a single step.
What the provenance might consist of,
will become clearer when Jeffrey
details the grammar rewrites
that the KHIL needs to perform.

```
    khil.brick(isym)
```
Given an internal symbol `isym`,
if `isym` is a brick symbol,
returns the
external symbol to which it corresponds.
Return `nil` if `isym` is a mortar symbol.

### External symbol accessors
```
    khil.lhs(xsym)
    khil.rhs(xsym)
```
`khil.lhs()` returns a list of the alternatives
which have `xsym` on their LHS.
`khil.rhs()` returns a list of the alternatives
which have `xsym` on their RHS.

### Alternative accessors
```
    khil.alternative_rule(alt)
    khil.alternative_text(alt)
    khil.alternative_pos(alt)
```
In the above statements, `alt` is the ID of an alternative.
The first call, `khil_alternative_rule()`,
returns the ID of the external rule to which `alt` belongs.
The second call, `khil_alternative_text()`,
returns a string which contains the text
of `alt` in the LUIF.
The third call, `khil_alternative_pos()`,
returns a list of two integers,
representing the start and end lexical positions of the
text returned by
`khil_alternative_text()`.

### External rule accessors
```
    khil.rule_text(xrule)
    khil.rule_pos(xrule)
```
In the above statements, `xrule` is the ID
of an external rule.
The first call, `khil.rule_text()`,
returns a string which contains the text
of `xrule` in the LUIF.
The second call, `khil.rule_pos()`,
returns a list of two integers,
representing the start and end lexical positions of the
text returned by
`khil.rule_text()`.

### Position accessors
```
   khil.lc(pos)
```
Given `pos`, a position in the LUIF,
as returned by the other KHIL callbacks,
`khil.lc(pos)` returns a list of two
integers.
These are line and column in the LUIF.
Line and column should be as defined
by the Unicode Consortium.

<!---
vim: expandtab shiftwidth=4
-->
