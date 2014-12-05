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
    local found_priority, found_length
    Lexeme loop: For every lexeme
        If found && lexeme priority != found_priority, end the lexeme loop
	If found && maximum_length < found_length,
	     end the lexeme loop
	local hit = OFF
	Pattern loop: For every pattern
	    if the pattern is memoized
		if memoized hit, hit = ON
	    else
		matches = match pattern and input string
		memoized matches
		if matches hit = ON
	    fi
	    if hit, exit pattern lopp
	end pattern loop
	if not hit, next lexeme loop
	local hit_length = length of hit
	if not found
	    found = ON
	    found_length = hit_length
	    found_priority = hit_priority
	    lexemes_list = singleton list containing hit
	    next lexeme_loop
	fi
	if hit_length < found_length, next lexeme_loop
	if hit_length > found_length,
	    clear lexemes list
	fi
	found_length = length
	add hit to lexemes_list
    end lexeme loop
    return lexemes_list

```
