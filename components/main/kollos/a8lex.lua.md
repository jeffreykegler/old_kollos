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
It's an optional part of Kollos's recognizer.

Kollos allows custom lexers,
and this source also contains
the description of the interface
for lexers in general.

## The lexer interface

This code is for one of the character readers,
which in turn is a kind of lexer.

The lexer interface offers the following methods:

### `iterator()`

`iterator()` returns a coroutine that produces the
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

## The lexer coroutine

The lexer coroutine, when resumeed,
takes no argumentes.
On yielding, it returns a table of mxid's.
At end of input, the table is empty.

## Constructor
 
This is an abstract factory method.
It returns another factory,
one which will, once the recce has been created and the
input is known, will create the lexer.

    -- luatangle: section Advertized methods
    -- luatangle: insert a8 memos key declaration

    local a8_memos_key
    local function a8lex_new(grammar)
         -- Add error checking
         local a8_memos = grammar[a8_memos_key]
         if not a8_memos then
             grammar[a8_memos_key] = {}
         end
         return a8_concrete_factory
    end

This table is used as the key for the memoization
of ASCII-8 characters.
It is empty and stays empty --
it's purpose in life is to create an unique address,
one which can be used as a key to grammar field
without fear of conflict.

This is hardly necessary for the lexers which
come bundled with Kollos, but custom lexers will
need to make sure the use keys which do not conflict
with any grammar fields, present or future.

    -- luatangle: section a8 memos key declaration

    local a8_memos_key = {}

## The concrete lexer factory

This method takes a blob name and an input
specification and returns a lexer.

    -- luatangle: section Concrete lexer factory

    local function a8_concrete_factory(
        blob, input_string, start_pos, end_pos)
        local lexer = {}
        -- luatangle: insert Declare a8_iterator_cofn
        local iterator = coroutine.create(a8_iterator_coro)
        return { iterator = iterator }
    end

## The A8 lexer iterator co-function

    -- luatangle: section Declare a8_iterator_cofn

    local a8_interator_cofn = function (parent_pos)
    end

## Finish and return the a8lex class object

    -- luatangle: section Finish and return object

    local a8lex_class = {
        new = a8lex_new,
        memo_key = a8_memo_key,
    }
    return a8lex_class

## Output file

    -- luatangle: section main
    -- luatangle: insert Concrete lexer factory
    -- luatangle: insert Advertized methods
    -- luatangle: insert Finish and return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
