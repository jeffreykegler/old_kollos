# Kollos: the intermediate representation

## Overview

Kollos's interface language will be the LUIF, essentially
Lua 5.1 extended with BNF.
A top layer, called the Kollos high layer, or KHIL,
will parse this into the "Kollos intermediate representation",
or KIR,
which is pure Lua 5.1 with some calls to the kollos Lua package.

Since the KIR is pure Lua 5.1, it can be run with Lua.
Calls in the kollos package, which I expect I will write,
will then do lower level transformations to make the grammar
ready for Libmarpa.
These lower level transformations are called the Kollos lower
layer, or KLOL.

This document describes

* the "kollos" Lua package calls in the KIR.

* the KHIL "callbacks", which allow the KLOL to get information
  from the KHIL for error messages, tracing, debugging, etc.

## The Kollos higher layer

The basic transformation needed to obtain the KIR from the LUIF is
translation of the LUIF rules, which may include precedented and
sequence rules, into a form which allows only BNF rules.
I will describe the transformations necessary to translate from
precedented rules to BNF rules,
and from sequence rules to BNF rules,
in separate documents.

## KHIL callbacks

For error messages, debugging, etc.,
the KIR will need to be able to access the original LUIF
text, given a rule, an alternative or a symbol.
These calls allow that.

*[ to be continued ]*

<!---
vim: expandtab shiftwidth=4
-->
