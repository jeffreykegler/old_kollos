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
 
This is a factory method.
Once the recce is known,
it will create the lexer.
Using a factory serves two purposes:

* It is a convenient way to specify a default lexer for
  a grammar.  All default lexers must present the
  standard string-oriented interface.

* It allows the use of upvalues,
  access to which is more
  efficient thank the hashed lookup

    -- luatangle: section Static methods

    local function factory(
        recce, blob_name, lex_string)
        local blob_name_type = type(blob_name)
        if blob_name_type ~= 'string' then
            return nil,lexer:development_error(
                "a8_lexer:abstract_factory(): blob_name is type '"
                    .. blob_name_type
                    .. "' -- it must be a blob_name")
        end
        local string_type = type(lex_string)
        if string_type ~= 'string' then
            return nil,lexer:development_error(
                "a8_lexer:abstract_factory(): string is type '"
                    .. string_type
                    .. "' -- it must be a string")
        end

        local grammar = recce.grammar
        local mxids_by_cc = grammar.mxids_by_cc
        local mxids_by_byte = grammar[a8_memos_key]
        if not mxids_by_byte then
            mxids_by_byte = {}
            grammar[a8_memos_key] = mxids_by_byte
        end
        local down_pos = 0
        local up_pos = 0
        local end_of_input = #lex_string
        local up_history = {}
        local throw = recce.throw

        -- luatangle: insert define lexer blob() method
        -- luatangle: insert define lexer next() method
        -- luatangle: insert define lexer resume() method

        local lexer = {
            next_lexeme = next_method,
            resume = resume_method
        }
        return lexer
    end

## The memos key

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

## Down positions

Down positions are positions in the layer below
the lexer.
These must be in term accessible to the layer above
the lexer, so that it can use the `resume()` method.

It may the case that the positions accessible to the
upper layer are not the useful one.
For example, the useful positioning 
in a UTF-8 lexer's will be by codepoint,
but knowledge of that positioning is only available
within the lexer.
The upper layer will see the string as a sequence
of bytes.
If necessary, a method must be provided 
to translate from
useful values to down positions as visible to
the upper layer.

The down position is never `nil`.
An undefined down position is indicated by a value
one less than the `start_of_input`.
This is in order to optimize the `next()` method.
Optimization of `next()` is prefered because it is
the default, and in most cases the most called,
method.

## The blob name

The blob name is a string which will be used in error
messages.
Archetypally, the blog name is the file name.
For blobs which are not files,
the blob name
should be something
that helps the user identify where the error
occurred.

## The blob() lexer method

    -- luatangle: [ 
    section define lexer blob() method ]

    local function blob_method() return blob_name end

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

## The next() lexer method

    -- luatangle: section define lexer next() method

    local function next_method()
        down_pos = down_pos + 1
        up_pos = up_pos + 1
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

    local char = lex_string.char(byte)
    mxids_for_byte = {}
    for cc_spec,mxids_by_cc in pairs(mxids_by_cc) do
        local found = char:find(cc_spec)
        if found then
            for ix = 1,#mxids_by_cc do
                mxids_for_byte[#mxids_for_byte+1]
                    = mxids_by_cc[ix]
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
           end --12
        }
    )

## The resume() lexer method

"Resumes" a lexer at a new position.
Automatically sets a new up-position.
With no end_arg, defaults to #lex_string.
To set a new up-position without changing
the down positions, leave them nil.
If start_arg is nil, end_arg is always ignored.

    -- luatangle: section define lexer resume() method

    local function resume_method(start_arg, end_arg)
        local up_history_ix = #up_history
        local current_up_history = up_history[up_history_ix]

        -- If the old history entry was actually used
        if down_pos >= current_up_history[3] then
            -- Mark the end position where the last history
            -- segment ended
            up_history[up_history_ix][2] = up_pos
            -- Prepare to create a new history entry
            up_history_ix = up_history_ix + 1
        end --13

        -- start_arg and end_arg might both be nil
        if start_arg then
            start_of_input = start_arg
            if not end_arg then
                end_of_input = end_arg
            else
                end_of_input = #lex_string
            end
        end

        local current_up_pos = recce.current_pos()
        up_history[up_last_history_ix] = { current_up_pos, false, start_of_input }

        -- Undefined position is indicated as start less one
        -- to make the next() method efficient
        down_pos = start_of_input - 1
        up_pos = current_up_pos - 1

    end

## The value() lexer method

Using the up-history, find the value at 'up_pos_arg`.

    -- luatangle: section define lexer value() method

    local function value_method(up_pos_arg)
        if up_pos_arg > up_pos then
            return nil,lexer:development_error(
                "a8_lexer:value(): position is past last position read\n"
                    .. "  last position read: " .. up_pos .. "\n"
                    .. "  position argument: " .. up_pos_arg .. "\n"
            )
        end
        if up_pos_arg < 1 then
            return nil,lexer:development_error(
                "a8_lexer:value(): position argument is less than 1\n"
                    .. "  position argument: " .. up_pos_arg .. "\n"
            )
        end
        local most_recent_up_entry = up_history[#up_history]
        local start_of_up_range = most_recent_up_entry[1]
        local dpos_base

        -- The most recent entry is a special case, because it's
        -- end of up-range is not set.  Treating it as such
        -- has the benefit of optimizing the case where there
        -- is a single history entry, which should be the most
        -- common.
        if up_pos_arg >= start_of_up_range then
            dpos_base = most_recent_up_entry[3]
        else
            -- up_pos was not in range of last up-history entry, so
            -- binary search the others
            local lo = 1
            local hi = #up_history - 1
            -- avoid overflow
            while not dpos_base do
                if hi < lo then
                    return nil,lexer:development_error(
                        "a8_lexer:value(): Internal error\n"
                            .. "  position argument is not in lexer up-history: " .. up_pos_arg .. "\n"
                    )
                end
                local trial = ((hi - lo) / 2) + lo
                local trial_up_entry = up_history[trial]
                start_of_up_range = trial_up_entry[1]
                local end_of_up_range = trial_up_entry[2]
                if up_pos_arg > end_of_up_range then
                    lo = trial + 1
                elseif up_pos_arg < start_of_up_range then
                    hi = trial - 1
                else
                    dpos_base = trial_up_entry[3]
                end
            end
        end
        value_dpos = (up_pos_arg - start_of_up_range) + dpos_base
        return lex_string:sub(value_dpos, value_dpos)
    end

## Finish and return the a8lex class object

    -- luatangle: section Finish and return object

    local static_class = {
        factory = factory
    }
    return static_class

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
            file = lexer.blob,
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
    -- luatangle: insert Static methods
    -- luatangle: insert Finish and return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
