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
and provides a documented interface for them.
Since this source describes the most basic lexer,
we include the description of the lexer interface
here.
It precedes the description of the A8 lexer.

## The lexer interface

Kollos allows more than one lexer,
including customized lexers.
Lexers can also be stacked,
one above another, in a chain of command.

### What is a lexer?

*Lexer*, in this context, is a Kollos-specific term.
A Kollos recognizer has *layers*.
The top layer is special, and is called the *parser layer*,
or simply, *parser*.
All other layers are *lexer layers*,
or simply,
lexers.
Note that a lexer layer may have many implementations,
including implementations more than complicated enough
to justify the term "parser" in its ordinary, non-Kollos,
sense.

Every lexer layer has a parent layer.
The lexer layer passes a stream to its parent
layer,
where each element of the stream is a *set*
of symbols.
Each element of the stream is a *set* of symbols,
because Kollos allows ambiguous lexing.

Each stream element occurs at a stream position.
The positions in each stream are a 1-based sequence
of consecutive integers.

Position in the parent's stream is called *up-position*.
A layer will also have a concept of *down position*.
In a bottom layer, down-position may be anything convenient
for the lexer.
In a lexer layer which is not the bottom layers,
down-positions must also be the up-positions
of another lexer layer,
and therefore must be elements of a 1-based sequence of
integers.

## Lexer methods

### `blob()`

The blob name.
This must be the Lua string which was passed to
the lexer factory.
Archetypally, it will be a file name.
If the lexer is non-standard, the blob name
may be arbitrary,
but it should be as useful as possible for error
reporting.

### `iterator()`

`iterator()` returns a coroutine that produces the
series of lexemes.  This is described further below.

### `linecol(pos)`

If pos is a already visited up-position,
a lexer *must* be able
to report a line and column.
Line and column is used for error reporting.
A lexer must keep whatever history it needs to do this.

A "standard" lexer has inputs which are strings,
and will report line and column according to the Unicode
standard.

Line and column must always be two non-negative integers.
Line and column values of zero may be used,
but should be reserved for special cases.
Otherwise,
if the lexer is non-standard, its line and column
may be arbitrary,
but it should be as useful as possible for error
reporting.

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

### `sub(start_pos, end_pos)`

If every up-position in the range from
`start_pos` to `end_pos` is a visited position,
`sub(start_pos, end_pos)`
must return a string
somehow corresponding to
that range of up-positions.
A lexer must be able to detect if any up-position
in the range was not visited,
and must return a fatal error in that case.

In a "standard" lexer, inputs will be strings,
and `sub(start_pos, end_pos)` should be a substring
of the input string.

### Other lexer methods

A lexer will often have other methods,
special to it.
For example, a lexer will often want to allow
the application to manipulate its down-positions.

### Using the lexer iterator

The lexer iterator is a Lua coroutine.
It should be resumed with no arguments or one.
If the iterator is called with an argument,
that argument becomes the current up-position.
Usually the iterator will
*not* be called with an argument,
and the current up-position will be the default.

The default for the current up-position is 1 initially,
and is one plus the current position after that.
Since the up-positions in a lexer's parent layer must always
start at 1 and must be consecutive integers, this
will usually be what is wanted.

One example of a circumstance where the default current
up-position is not what is wanted,
is the case where two lexers are in use.
When the Kollos layer switches lexers,
it must inform
the lexer of its current up-position.

On yielding, the lexer coroutine returns

* On success before the end of input,
  the table of mxid's for the current up-position,
  This table must not be altered.

* On success at end of input, an empty table.

* On unthrown failure, two values: a `nil`,
  followed by an error object.

### The Ascii 8 lexer

## Constructor
 
This is an abstract factory method.
It returns another factory,
one which will,
once the recce is known,
will create the lexer.
For the a8 lexer, the abstract factory
does not do much.
But some lexers may want to do pre-processing
after the grammar is known,
but before the recognizer is known.
This stage of the process exists for the benefit of
those lexers.

    -- luatangle: section Advertized methods

    local function a8lex_new(grammar) -- luacheck: ignore grammar
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

    local function a8_concrete_factory(recce)
        local grammar = recce.grammar
        local lexer = {
            recce = recce,
            grammar = grammar,
            cc_by_mxids = grammar.cc_by_mxids,
            throw = recce.throw,
        }
        local a8_memos = grammar[a8_memos_key]
        if not a8_memos then
            grammar[a8_memos_key] = {}
        end
        return lexer
    end

## The blob_set() lexer method

The blob is a string which will be used in error
messages.
Archetypally, the blog name is the file name.
For blobs which are not files,
the blob name
should be something
that helps the user identify where the error
occurred.

    -- luatangle: section Lexer methods

    local function blob_set(
        lexer, blob, input_string, start_dpos, end_dpos)
        local blob_type = type(blob)
        if blob_type ~= 'string' then
            return nil,lexer:development_error(
                "a8_lexer:blob_set(): blob_name is type '"
                    .. type(blob)
                    .. "' -- it must be a string")
        end
        if lexer.blob then
            return nil,lexer:development_error(
                "a8_lexer:blob_set() called more than once\n"
                    ..  "  blob_set() can only be called once")
        end
        lexer.blob = blob
        lexer.input_string = input_string
        lexer.down_pos = start_dpos or 0
        lexer.up_pos = 0
        lexer.end_of_input = end_dpos or #input_string
        lexer.up_history = {}
        return lexer
    end

## The "Up history"

The A8 lexer's up history is a table of triples.
Each triple is `<u1,u2,d>`

* `u1` is start up-position

* `u2` is end up-position

* `d` is start down-position

It is expected,
for an up-position `u`
that is in the span from 
start up-position to
end up-position,
that down-position will be
`d + u - u1`.
In the last up-history,
the value of
`u2` may be a Lua `false`,
in which case the actual `u2`
value will be the current up-postion of
the lexer.

## The iterator() lexer method

    -- luatangle: section+ Lexer methods

    local function iterator(lexer)
        if not lexer.blob then
            return nil,lexer:development_error(
                "a8_lexer:iterator() called, but no blob set\n")
        end
        local lex_string = lexer.string
        local mxids_by_byte = lexer.mxids_by_byte
        local up_history = lexer.up_history
        -- luatangle: insert Declare a8_iterator_fn
        return a8_iterator_fn
    end

## The A8 lexer iterator co-function

    -- luatangle: section Declare a8_iterator_fn

    local a8_iterator_fn = function(up_pos_arg)
        local down_pos = lexer.down_pos
        if down_pos > lexer.end_of_input then
            return {}
        end
        down_pos = down_pos + 1
        lexer.down_pos = down_pos
        local up_pos = lexer.up_pos
        if up_pos_arg then
            if up_pos_arg <= up_pos then
                return nil,lexer:development_error(
                    "a8_lexer:iterator: attempt to use non-increasing up position\n"
                    .. " current up_pos = " .. up_pos .. "\n"
                    .. " up_pos arguments = " .. up_pos_arg .. "\n"
                )
            end
            if not up_history then
                lexer.up_history = { { up_pos_arg, false, down_pos } }
            else
                local last_history_ix = #up_history
                up_history[last_history_ix+1][2] = lexer.up_pos
                up_history[last_history_ix+1] = { lexer.up_pos_arg, false, down_pos }
            end
        else
            up_pos = up_pos + 1
            if not up_history then
                up_history = { { up_pos, false, down_pos } }
            end
        end
        lexer.up_pos = up_pos_arg
        local byte = lex_string:byte(down_pos)
        local mxids_for_byte = mxids_by_byte[byte]
        if not mxids_for_byte then
            -- luatangle: insert set mxids_for_byte
            mxids_by_byte[byte] = mxids_for_byte
        end
        return mxids_for_byte
    end

## Set the mxids entry for byte

    -- luatangle: section set mxids_for_byte

    local char = string.char(byte)
    mxids_for_byte = {}
    for cc_spec,mxids_for_cc in pairs(mxids_for_cc) do
        local found = char:find(cc_spec)
        if found then
            for ix = 1,#mxids_for_cc do
                mxids_for_byte[#mxids_for_byte+1]
                    = mxids_for_cc[ix]
            end
        end
    end
    if #mxids_for_byte <= 0 then
        local error_message = {
            "a8_lexer:iterator: character in input is not known to grammar\n",
            "   character value is ", byte, "\n"
        }
        if char:find('[^%c]') then
            error_message[#error_message+1] =
             "  character printable glyph is " .. char .. "\n"
        end
        return nil,lexer:development_error(
            table.concat(error_message)
        )
    end
    -- make these entries write only
    setmetatable(mxids_for_byte, {
       __newindex = function(table) 
                error("mxids by cc are write only")
           end
        }
    )

## Finish and return the a8lex class object

    -- luatangle: section Finish and return object

    local a8lex_class = {
        new = a8lex_new,
        memo_key = a8_memos_key,
    }
    return a8lex_class

## Development errors

    -- luatangle: section Development error methods

    local function development_error_stringize(error_object)
        return
        "A8 lexer error at line "
        .. error_object.line
        .. " of "
        .. error_object.file
        .. ":\n "
        .. error_object.string
    end

    local function development_error(lexer, string)
        local error_object
        = kollos_c.error_new{
            stringize = development_error_stringize,
            code = luif_err_development,
            file = lexer.blog,
            line = debug.getinfo(2, 'l').currentline,
            string = string
        }
        if lexer.throw then error(tostring(error_object)) end
        return error_object
    end

## Output file

    -- luatangle: section main
    -- luatangle: insert Development error methods
    -- luatangle: insert a8 memos key declaration
    -- luatangle: insert Lexer methods
    -- luatangle: insert Concrete lexer factory
    -- luatangle: insert Advertized methods
    -- luatangle: insert Finish and return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
