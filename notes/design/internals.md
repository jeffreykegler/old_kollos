Implementing the Kollos internals
=================================

These notes explain how Kollos will be implemented internally.
As I see it, the implementation divides into four large pieces:

* the grammar rewrite,
* lexing,
* the parse-time interface and
* the evaluation interface.

The grammar rewrite
-------------------
The SLIF worked by rewriting its grammar
into a form suitable for Libmarpa.  The LUIF will have to do the
same.

Lexing
------

The LUIF was allow multiple lexers.  Initially, we'll
require that a lexer be written by hand.
Next, we may allow the choice of a fast, Lua-pattern-driven
lexer, or a lexer which resembles that of the SLIF.

Parse-time interface
--------------------
The calls available for the SLIF must
be duplicated for the LUIF.  Translation from Kollos symbol
to Libmarpa symbol, and back, is the most tricky part of this.

Evaluation iterface
-------------------

The calls available for the SLIF must
be duplicated for the LUIF.  Again,
symbol translation is an issue.

As a later step, we may want to rewrite the ASF logic in 
C, and then base the evaluator on ASF's.
