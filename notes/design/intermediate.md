# Kollos: the intermediate representation

## Overview

[ This document is under construction.
Skimming should give some idea of the kinds of
information the KIR will need, at least.
]

Kollos's interface language will be the LUIF, essentially
Lua 5.1 extended with BNF.
A top layer, called the Kollos high layer, or KHIL,
will parse this into the "Kollos intermediate representation".
The Kollos intermediate representation,
also called the KIR,
is a Lua 5.1 table.

Since the KIR is a Lua 5.1 table, it can be read directly
by a Lua interpreter.
The KIR table will be the input to the lower
layer of Kollos, the KLOL,
which at this point Jeffrey expects that he will write.
The KLOL will do make it ready for Libmarpa.

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
Jeffrey will describe the transformations necessary
for the KHIL to translate from
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

## The KIR table

The KIR table consists of a key-value pair
for each grammar.
While the LUIF will be able to define many
grammars,
the most important setup will be the
case where there are two:

* a structural grammar named `g1`; and

* a lexical grammar named `l0`,
  which is linked to `g1`.

The value of the KIR tables key-value
pairs will be another table,
the KIR grammar table.

## Terminology

In what follows, an *ID*, such
as a rule ID or a symbol ID
is always an integer.

A *property table*
is a Lua table
in which the key
of the key-value pair
is the name
of a property,
and the value
of the key-value pair
is the property's value.

A *database table* is a
Lua table
whose keys are IDs or symbol
names,
and whose values are property
tables.

### KIR grammar tables

A KIR grammar table is
a property table,
some of whose property values
are databases.
Its contents are not fully
worked out, but some of its
keys are:

* `xrule`.  Required.
  The value is the external rule
  database, described below.

* `alt`.  Required.
  The value is the alternative
  database, described below.

* `irule`.  Required.
  The value is the internal rule
  database, described below.

* `xsym`.  Required.
  The value is the external symbol
  database, described below.

* `isym`.  Required.
  The value is the internal symbol
  database, described below.

* `structural`  Optional.
  Non-nil if and only if this is
  a structural grammar.

### The external symbol database

The external symbol database table
is keyed by symbol name.

* 'location` -- Required.
  A location object.

### The internal symbol database

The internal symbol database table
is keyed by symbol name.
In its property tables,
the keys are

* 'terminal` -- Optional.
  Present and true if and only
  if the internal symbol
  is a terminal.

* 'start` -- Optional.
  Present and true if and only
  if the internal symbol
  is the start symbol.

* 'brick` -- Optional.
  Present and true if and only
  if the internal symbol
  is a brick symbol.
  If present, its value
  is the name of the external
  symbol to which the
  internal symbol corresponds.

* `provenance` -- Required.
  Not fully worked out.
  An array describing how the
  internal symbols was created.

### Provenance

For tracing and debugging,
it may be necessary to know where
an internal symbol came from.
Its provenance describes this.

Many provenances will contain only
one entry.
A terminal symbol, for example,
must be a brick
created directly from an external
symbol.
Or a mortar symbol may be
a LHS created for a sequence
rule, and may have unchanged
from that point.
In other cases, symbols
may be created from
other created symbols,
and the provenance could be
quite lengthy.

### The external rule database

The external rule database is a Lua table.
Each key
is an external rule ID.
In its property tables,
the keys are

* 'location` -- Required.
  A location object.

* 'type` -- the type of the external rule.
  Required.
  This is one of `sequence`, `precedenced`,
  or `BNF`.

### The alternative database

The alternative database is a Lua table.
Each key is an alternative ID.
In its property tables,
the keys are

* 'location` -- Required.
  A location object.

* 'xrule` -- Required.
  The external rule of which this
  alternative forms a part.

* 'type` -- the type of the alternative.
  Required.
  one of `sequence`, `precedenced`,
  or `BNF`.
  Because rules can occur within rules,
  this is not necessarily the same
  as the type of `xrule`.

* `lhs` -- the symbol name of the LHS symbol

* `rhs` -- an array of the names of the RHS
  symbols.

* 'semantics` -- Required?
  Not fully worked out,
  but a property table describing
  the semantics.

### The internal rule database

The internal rule database is a Lua table.
Each key
is an internal rule ID.
Rule IDs are integers.
The values in the database are "property tables",
Lua tables in which the key
of the key-value pair
is the name
of a property,
and the value
of the key-value pair
is the property's value.

* `lhs` -- the symbol name of the LHS symbol

* `rhs` -- an array of the names of the RHS
  symbols.

* `alt` -- The ID of the corresponding alternative.

* `top` -- Non-nil if and only if this is the
  top rule of the alternative.

As we will see when Jeffrey describes the
grammar rewrites, alternatives
may be broken up into many internal rules.
Of the rules into which an alternative is broken up,
one and only one will be the "top" rule.
Only the top rule of an alternative will have a semantics
associated with it.

<!---
vim: expandtab shiftwidth=4
-->
