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

Grouping and hidden symbols
===========================

To group a series of RHS symbols use parentheses:
```
   ( A B C )
```
You can also use square brackets,
in which case the symbols will be hidden
from the semantics:
```
   [ A B C ]
```

Parentheses and square brackets can be nested.
If square brackets are used at any nesting level
containing a symbol, that symbol is hidden.
In other words,
there is no way to "unhide" a symbol that is inside
square brackets.

Sequences
=========

Sequences are expressions on the RHS of a BNF rule alternative
which imply the repetition of a symbol,
or a parenthesized series of symbols.

The syntax is inspired by
Perl6
[see Synopsis 5](http://perlcabal.org/syn/S05.html).
Those familar with Perl 6 syntax, however,
need to be careful, because the meanings
are often quite different.
Perl 6 syntax is designed with regular expressions
in mind.
LUIF syntax is general BNF -- more more powerful
and quite different.

For example, in Perl 6 `**` means a greedy match.
In the LUIF it means just a match -- if there's more
than one possibility, it means all of them.
As another example, 
the Perl 6 syntax specifies
treatment of whitespace
In the LUIF, whitespace handling is taken
care of the lexer.
The rules for the structural grammar have nothing
to do with it.

The item to be repeated (the repetend)
can be either a single symbol,
or a sequence of symbols grouped by
parentheses or square brackets,
as described above.
A repetiton consists of

+ A repetend, followed by
+ An optional puncuation specifier.

A repetition specifier is one of

```
    ** N..M     -- repeat between N and M times
    ** N..*     -- repeat more than N times
    ?           -- equivalent to ** 0..1
    *           -- equivalent to ** 0..*
    +           -- equivalent to ** 1..*
```

A punctuation specifier is one of
```
    % <sep>     -- use <sep> as a separator
    %% <sep>     -- use <sep> as a terminator
```
When a terminator specifier is in use,
the final terminator is optional.

Here are some examples:

```
    A+                 -- one or more <A> symbols
    A*                 -- zero or more <A> symbols
    A ** 42            -- exactly 42 <A> symbols
    <A> ** 3..*        -- 3 or more <A> symbols
    <A> ** 3..42       -- between 3 and 42 <A> symbols
    (<A> <B>) ** 3..42 -- between 3 and 42 repetitions of <A> and <B>
    [<A> <B>] ** 3..42 -- between 3 and 42 repetitions of <A> and <B>,
                       --   hidden from the semantics
    <a>* % ','         -- 0 or more comma-separated <a> symbols
    <a>+ % ','         -- 1 or more comma-separated <a> symbols
    <a>? % ','         -- 0 or 1 <a> symbols; note that ',' is never used
    <a> ** 2..* % ','  -- 2 or more comma-separated <a> symbols
    <A>+ % ','         -- one or more comma-separated <A> symbols
    <A>* % ','         -- zero or more comma-separated <A> symbols
    (A B)* % ','       -- A and B, repeated zero or more times, and comma-separated
    <A>+ %% ','        -- one or more comma-terminated <A> symbols

```

The repetend cannot be nullable.
If a separator is specified, it cannot be nullable.
If a terminator is specified, it cannot be nullable.
If you try to work out what repetition of a nullable item actually means,
I think the reason for these restrictions will be clear --
such a repetition is very ambiguous.
An application which really wants to specify rules involving nullable repetition,
can specify them directly in BNF,
and these will make the programmer's intent clear.

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
