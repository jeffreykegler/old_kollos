The LUIF Lexers
===============

[ Under construction.  DO NOT USE! ]

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

lexer_create()
--------------

Returns a new lexers, with no lexemes, pattern
or strings.
Note: right now conflate lexer as grammar with
lexer as processor.

lexeme_register()
-----------------

   * name -- Lua var, plus allow '-' -- required
   * ID -- G1 ID number -- required
   * active -- starts active?  default is yes
   * priority -- number ?  default is zero

Lexeme is created with no patterns, which means it
will never match.

pattern_register()
------------------

   * pattern -- a Lua pattern
   * length -- its maximum length.  Default is infinite.

pattern_associate(lexeme, pattern)
----------------------------------
  
Associate pattern with lexeme.

lexeme_priority_set(lexeme, priority)
---------------------

Change the priority of the lexeme.

input_string_register(string)
-----------------------------

Register an input string.
Returns a "string object".

lexer_position(pos, [string_obj])
-----------------------------

Set pos as the position in the current input string.
If "string_obj" is specified, also sets a new input string.

The algorithm
-------------

Input is a series of lexeme ID's.
These will be acceptable lexemes as returned by the
G1 parser.


```
    Filter out all inactive lexemes
    First, sort all lexemes by length within priority
    Set hit to OFF
    Set found to OFF
    Set the lexeme accepted flag to OFF
    Set accepted priority = 0
    Set accepted length = 0
    Lexeme loop: For every lexeme
        If lexeme priority < accepted priority, end the lexeme loop
	If found && maximum_length < (length of found lexemes),
	     end the lexeme loop
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
