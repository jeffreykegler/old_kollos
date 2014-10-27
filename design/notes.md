Kollos design notes
===================

These are design notes toward Kollos, a Lua-driven extension of,
and wrapper for Libmarpa.

Kollos's interface will be the LUIF, a successor to Marpa::R2's
SLIF.  Unlike the SLIF, LUIF will contain a small
Turing-complete language -- Lua.

The LUIF
========

The LUIF will be Lua, extended with BNF statements.
In designing the LUIF, preference will be given to having
its statements be exactly like pure Lua.
Exceptions will be made only when other considerations
considerably outweigh the convenience of adhering to a familiar,
well-known and well-documented standard.

At the moment, and possibly forever, the only extension
which meets this criterion are BNF statements.
These are an extremely well-known and familar way of expressing
grammar rules.
Individual features of BNF statements will also have to meet
the "clearly better than pure Lua" test.
If a BNF extension
clearly fits BNF well and works far more naturally as
an extension to BNF than as a standard Lua call,
then it will be added to BNF.
(The SLIF's use of '||' for precedence is one such example.)
Otherwise, pure Lua will be preferred.

BNF statements
==============

There is only one BNF statement,
combining priorities, sequences, and alternation.
The SLIF's sequence notation is extended to counted sequences,
and a separator notation adopted from Perl 6 is used.

A LUIF symbol name is any valid Lua name.
In addition, names with non-initial hyphens are allowed.
Eventually an angle bracket notation for LUIF symbol names,
similar to that of the SLIF, will allow whitespace
in names.

Here is an example of a LUIF BNF statement:

```
    Script ::= Expression+ % comma
    Expression ::=
      Number
      | left_paren Expression right_paren
     || Expression exp Expression
     || Expression mul Expression
      | Expression div Expression
     || Expression add Expression
      | Expression sub Expression
```
Grammars
========

BNF statements may be grouped into one or more grammars, or left in a default grammar.
It is a fatal error to try to do both --
that is, no Lua script with one or more rules in the default grammar may have a rule in an explicit grammar, and vice versa.

The syntax for an explicit grammar is similar to that for an anonymous function:

```
    g = grammar ()
    local x = 1
      a ::= b c
      w ::= x y z
      -- not just BNF, but pure Lua statements are allowed in a grammar
      for i = 2,n do
        x = x * i
      end
    end
```

Default grammar
---------------

A LUIF script has a top-level default grammar set, if it contains no explicit grammars.
If the LUIF script has explicit grammars, there is no top-level default grammar,
but the block of each grammar has a default grammar defined,
The default grammar of 
a `grammar` expression
will be returned as the value of the the `grammar` expression.

All BNF statements add results to the default grammar that is current in its scope.

Grammar objects
---------------

Grammar objects in fact may define two Libmarpa grammars: a structural grammar
and a lexical grammar.
The structural grammar is defined by those BNF rules which use the `::=` operator,
and the lexical grammar is defined by those BNF rules which use the `~` operator.
