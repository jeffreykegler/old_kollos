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

# Kollos "mid-level" recognizer code

This is the code for the "middle layer" recognizer
of Kollos.
Below it is Libmarpa, a library written in
the C language which contains the actual parse engine.

## Constructor

    -- luatangle: section Constructor

    local function recce_new(grammar)
        local recce = {
             down_history = {},
             grammar = grammar,
             throw = grammar.throw,
             down_pos = 0
        }
        local r = wrap.recce(grammar.libmarpa_g)
        recce.libmarpa_r = r
        setmetatable(recce, {
                __index = recce_class,
            })
        return recce
    end

## Declare the recce class

    -- luatangle: section Declare recce_class
    local recce_class = {}
    recce_class.bocage_new = bocage.new

## The start() method

    -- luatangle: section start() recce method

    function recce_class.start(recce)
        local r = recce.libmarpa_r
        return r:start_input()
    end

## The "down history"

This is the history of the downward position.
It is an array of entries.
Each entry is a duple `<dpos1, lexer>`,
where `dpos1` is the first down position to be used
for `lexer`.

Since the down positions are an integer sequence without
gaps, the `dpos1` duple elements of the next down-history
entry is one after the last down position of the current one.
For the last down-history entry, the last down position
is the current value of `down_pos` for the recce.

Down-history entries are added prospectively,
so that the most recent may never have been used.
This is the case if and only if
`down_pos < down_history[#down_history][1]`.

If a new down history entry is to be added
to a down history whose most recent entry is
unused,
the unused (most recent) entry must be deleted
first.

## The lexer_set() method

    -- luatangle: section lexer_set() recce method

    function recce_class.lexer_set(recce, lexer)
        recce.lexer = lexer
        local down_history = recce.down_history

        -- Set the down history index for a new
        -- entry.
        local down_history_ix = #down_history

        -- The entry must be incremented, unless the most
        -- recent entry has never been used -- in that case,
        -- the most recent entry is replaced
        if down_history_ix > 0 and
                recce.down_pos >= down_history[down_history_ix][1] then
             down_history_ix = down_history_ix + 1
        end

        -- This lexer's positions will
        -- start *after* down_pos is incremented.
        down_history[down_history_ix] = { recce.down_pos + 1, lexer }
    end

## The current_pos() method

Return the current down position.
Among other uses,
it allows the lexer's access to this datum.

    -- luatangle: section current_pos() recce method

    function recce_class.current_pos(recce)
        return recce.down_pos
    end

## The read() method

Requires a lexer to be set.
Reads for as long as it returns symbols
or, in other words,
until an event occurs.

    -- luatangle: section read() recce method

    function recce_class.read(recce)
        local lexer = recce.lexer
        if not lexer then
            return nil, lexer:development_error(
                "recce:read(): No lexer\n"
                .. "  Lexer must be set before calling read() method\n"
                )
        end
        while true do
            local symbols, error_object = lexer.next_lexeme()
            if symbols == nil then return nil, error_object end
            if #symbols < 1 then return recce.down_pos end
            -- Note: recce current pos is set only *after success*
            -- of next() method call
            recce.down_pos = recce.down_pos + 1
            -- luatangle: insert scan symbols into recce
        end
    end

    -- luatangle: section scan symbols into recce

    for _,symbol in ipairs(symbols) do
        local tokens_accepted = 0
        print("@" .. recce.down_pos, symbol, lexer.value(recce.down_pos))
        if recce.libmarpa_r:alternative(symbol) then
            tokens_accepted = tokens_accepted + 1
            -- print("Character accepted", describe_character(byte),
            -- "as", lex_g.symbol_by_libmarpa_id[tokens[token_ix]].name)
            -- else
            -- klol_progress_report(klol_r)
            -- print("Character not accepted", describe_character(byte),
            -- "as", lex_g.symbol_by_libmarpa_id[tokens[token_ix]].name)
        end
        if tokens_accepted <= 0 then
            print("Rejection at down position:", recce.down_pos)
            return
        end
        local event_count -- luacheck: ignore event_count
            = recce.libmarpa_r:earleme_complete() -- luacheck: ignore result
    end

# The progress report

    -- luatangle: section progress_report() recce method

    function recce_class.progress_report(recce, earley_set)
        local libmarpa_r = recce.libmarpa_r
        local grammar = recce.grammar
        local irule_by_mxid = grammar.irule_by_mxid
        local latest_earley_set =
            earley_set or libmarpa_r:latest_earley_set()
        print("Earley set " .. latest_earley_set)
        libmarpa_r:progress_report_start(latest_earley_set)
        while true do
            local rule_id, position, origin = libmarpa_r:progress_item()
            if not rule_id then break end
            local irule = irule_by_mxid[rule_id]
            -- print(inspect(irule, { depth = 4 }))
            -- print("@" .. origin .. '-' .. latest_earley_set, rule_id, position)
            print("@" .. origin .. '-' .. latest_earley_set ..
                "; " .. irule:show_dotted(position))
        end
        libmarpa_r:progress_report_finish()
    end

    --[===[ stuff that may prove useful --

    -- local err_none = kollos.error.code_by_name['LUIF_ERR_NONE']
    local err_unexpected_token_id = kollos.error.code_by_name['LUIF_ERR_UNEXPECTED_TOKEN_ID'] -- luacheck: ignore
    -- print(inspect(kollos.event))
    local symbol_completed_event = kollos.event.code_by_name['LIBMARPA_EVENT_SYMBOL_COMPLETED']
    local symbol_exhausted_event = kollos.event.code_by_name['LIBMARPA_EVENT_EXHAUSTED']

    local function describe_character(byte)
        local printable_description = ''
        local char = string.char(byte)
        if char:find('^[^%c%s]') then
            printable_description = '"' .. char .. '", '
        end
        return printable_description .. string.format("0x%.2X", byte)
    end

    local function result_for_events(lexer, last_completions, last_completions_cursor)
        -- print("Events!", #last_completions)
        local result_table = { lexer.cursor, last_completions_cursor }
        for event_ix = 1, #last_completions do
            local event_value = last_completions[event_ix]
            result_table[#result_table + 1] = event_value
        end
        lexer.cursor = last_completions_cursor + 1
        return result_table
    end
    ]===]

## The recce values() method

This method returns an interator of the values of
the parse for external symbol `xsym`,
starting at earleme location `start`
and ending at earleme location `current`.

    -- luatangle: section values() recce method
    function recce_class.values(recce, xsym, start, current) -- luacheck: ignore recce current
        if xsym ~= nil then
            development_error(
                'values() symbol argument not yet implemented\n'
                .. '  It must be nil\n'
            )
        end
        if start ~= nil then
            development_error(
                'values() start argument not yet implemented\n'
                .. '  It must be nil\n'
            )
        end
    end

## Finish and return the recce static class

    -- luatangle: section Finish return object

    local recce_static_class = {
        new = recce_new
    }
    return recce_static_class

## Development errors

    -- luatangle: section Development error methods

    local function development_error_stringize(error_object)
        return
        "recce error at line "
        .. error_object.line
        .. " of "
        .. error_object.file
        .. ":\n "
        .. error_object.string
    end

    local function development_error(recce, string)
        local blob = 'No blob'
        if recce.lexer then
             blob = recce.lexer.blob()
        end
        local error_object
        = kollos_c.error_new{
            stringize = development_error_stringize,
            code = luif_err_development,
            file = blob,
            line = debug.getinfo(2, 'l').currentline,
            string = string
        }
        if recce.throw then error(tostring(error_object)) end
        return error_object
    end

## Output file

    -- luatangle: section main

    -- luacheck: std lua51
    -- luacheck: globals bit
    -- luacheck: globals __FILE__ __LINE__

    -- local inspect = require "kollos.inspect"
    local wrap = require "kollos.wrap"
    local bocage = require "kollos.bocage"
    local kollos_c = require "kollos_c"
    local luif_err_development = kollos_c.error_code_by_name['LUIF_ERR_DEVELOPMENT']

    -- luatangle: insert Declare recce_class
    -- luatangle: insert Development error methods
    -- luatangle: insert Constructor
    -- luatangle: insert start() recce method
    -- luatangle: insert lexer_set() recce method
    -- luatangle: insert current_pos() recce method
    -- luatangle: insert read() recce method
    -- luatangle: insert progress_report() recce method
    -- luatangle: insert values() recce method
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
