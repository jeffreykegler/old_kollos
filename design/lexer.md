The LUIF Lexers
===============

[ Under construction.  DO NOT USE! ]

The LUIF will allow multiple lexers.
Lexers will call back to the parser (using Lua co-routines).
There will be the following callbacks to do the following

* Add a lexeme alternative

* Complete the lexemes at that location

* Return events

   - rejection
   - asynchronous exhaustion
   - the other non-lexeme events as currently implemented in the SLIF

The basic LUIF lexer
====================

The default LUIF lexer will be much faster but less powerful
than that of the SLIF.
It will allow the user to associate lexemes with one or
more Lua patterns.
Lexemes may also

*  Have a priority, as in the SLIF

*  Be able to be activated, or deactivated

Patterns have a maximum length, although this may be infinite.
For the purpose computing pattern and lexeme lengths, infinity
is considered to be larger than any integer.
Patterns whose length cannot be determined are treated as infinite
in length
A lexeme's length is the length of its longest patterns.


The algorithm
-------------

*[ Under construction!  DO NOT USE! ]*

```
    First, sort all lexemes by length within priority
    Set the lexeme accepted flag to OFF
    Set accepted priority = 0
    Set accepted length = 0
    Lexeme loop: For every lexeme
        If the lexeme is not acceptable, skip to the next lexeme
        If the lexeme is not activated, skip to the next lexeme
        If lexeme priority < accepted priority, end the lexeme loop
        If the lexeme accepted flag is ON
            If lexeme length < accepted length, end the lexeme loop
	    end if
	end if
	Pattern loop: For every pattern
		if the pattern is memoized
		     set value to the memoized value
		otherwise, try to match the Lua pattern and
		     set value to the result
	        end if
	        if the value is FAIL skip to the next pattern
	        do an "alternative" callback
		memoized the pattern
	        set lexeme accepted to ON
	        skip to the next lexeme
	    end pattern loop
    end lexeme loop
    if a lexeme was accepted
	    do a "completion" callback
	    generate the resulting events for Lua
    Otherwise, generate a "rejection" callback
    end main lexer code
```
