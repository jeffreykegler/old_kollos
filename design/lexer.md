The LUIF Lexers
===============

[ Under construction.  DO NOT USE! ]

The LUIF will allow multiple lexers.
We need calls to

* Register a lexeme

* Register a pattern

* Associate a pattern to a lexeme

* Change the priority of a lexeme

* Register an input string

* Set the current string and position

* Given a set of lexeme ID's, match them the current string-position
Return events

   - a list of lexemes
   - rejection
   - asynchronous exhaustion
   - the other non-lexeme events as currently implemented in the SLIF

