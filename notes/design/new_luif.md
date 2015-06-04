# Suggested LUIF syntax, 3 June 2015

This is for a seamless grammar -- a lexer with a single lexeme. Lexers
allow semantics in Kollos, so this does everything.


    seamless l0.E
       (number) -> number
       || (E ws? '*' ws? E) -> E:1*E:2
       || (E ws? '+' ws? E) -> E:1+E:2
    token ws ([\009\010\013\032]) -> nil
    token l0.number ([%d]+)

## Guide to the syntax

`seamless` and `token` are keywords.  `seamless` indicates the top
of a seamless grammar -- one that is lexical, with only one lexeme.
Lexers in Kollos allow semantics, and the semantics of a seamless grammar
will usually be important.

Rules are in the form lhs (rhs) -- they are treated as functions a la
recursive descent and/or Perl 6.  But the implementation is Marpa, and
`lhs (rhs)` is equivalent to `lhs ::= rhs`.  For example, there can be
more than one rule with the same "lhs".

A precedenced rule is shown by separating the RHS's with `||`, as is
done in the SLIF.

Semantics is Lua code either is curly braces (`{}`) or preceeded by a
"does" operator (`->`).  The curly brace form is not shown.  When a
"does" operator is used, what follows it must be a single Lua expression.

    -> { E:1 * E:2 }

is the same as

    { return E:1 * E:2 }

The `E:1` and `E:2` variables refer to the RHS, or child values. `E:1`
is the value of the first instance of `E` on the RHS.  Currently `E+E`
would mean `E:1+E:1`, but it might be nice to have it mean `E:1+E:2` --
that is, if there is more than one `E` on the RHS, each E in the semantics
corresponds to the RHS instances of `E` in order, with the last reused
if there are more instances of `E` in the semantics than on the RHS.

Where the LHS is qualified -- for example `l0.E`, that indicates symbol
`E` in the `l0` grammar.  The LUIF will allow several grammar to be defined
as once.  Qualifying the LHS with a grammar names affects the entire rule.
If no grammar name is specified, the last one explicitly specified is used.

## Rough SLIF equivalent

There is no exact equivalent in the SLIF, but this grammar is in sort of
"in the same spirit":

```
   E ::= Number
       || E '*' E action => do_multiply
       || E '+' E action => do_add
   Number ~ [\d]+

   :discard ~ whitespace
   whitespace ~ [\s]+
 ```

