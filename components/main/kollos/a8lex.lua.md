<!--

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[ MIT license: http://www.opensource.org/licenses/mit-license.php ]

-->

# Kollos 8-bit ASCII reader code

This is the code for the Kollos's 8-bit ASCII
character reader.
It's an optional of Kollos's recognizer.

## The lexer interface

This code is for one of the character readers,
which in turn is a kind of lexer.

The lexer interface offers the following methods:

### `coro()`

`coro()` returns a coroutine that produces the
series of lexemes.  This is described further below.

### `value(pos, symbol)`

`value(pos, symbol)` returns the value of `symbol`
at `pos` for this lexer.  The lexer is expected to
be able to reconstruct values cheaply, or else to
memoize them.

If `symbol` is `nil`, then one of
the values, chosen arbitrarily,
is returned.
Most often, there is only one value,
or all symbols at `pos` have the same
value, so that the "arbitrary" choice
among the values is in fact precisely
determined.

### `linecol(pos)`

Returns two values -- the line and column corresponding
to `pos`.
These must be integers if `pos` was a visited location.
but what they mean is up to the lexer.

A "standard" lexer assumes has inputs
which are strings containing text files,
and reports line and column according to the Unicode
standard.

### `blob()`

The blob name.
This must be the Lua string which was passed to
the lexer factory.
Archetypally, it will be a file name.

## The lexer cooroutine

The lexer cooroutine, when resumeed,
takes no argumentes.
On yielding, it returns a table of mxid's.
At end of input, the table is empty.

## Constructor
 
This is an abstract factory method.
It returns another factory,
one which will, once the recce has been created and the
input is known, will create the lexer.

    -- luatangle: section Advertized methods

    local function a8lex_new(grammar)
         -- Add error checking
         local a8_memos = grammar[a8_memos_key]
         if not a8_memos then
             grammar[a8_memos_key] = {}
         end
         return {}
    end

## The concrete lexer factory

This method takes a blob name and an input
spefication and returns a lexer.

## Finish and return the a8lex class object

    -- luatangle: section Finish and return object

    local a8lex_class = {
        new = a8lex_new
    }
    return a8lex_class

## Output file

    -- luatangle: section main
    -- luatangle: insert Advertized methods
    -- luatangle: insert Finish and return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
