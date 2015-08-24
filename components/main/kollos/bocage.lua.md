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

# Kollos "mid-level" bocage code

This is the code for the "middle layer" bocage
of Kollos.
Below it is Libmarpa, a library written in
the C language which contains the actual parse engine.

## Constructor

    -- luatangle: section Constructor

    local function bocage_new(recce)
        local grammar = recce.grammar
        local bocage = {
             grammar = grammar,
             libmarpa_g = grammar.libmarpa_g,
             throw = recce.throw,
        }
        local b = wrap.bocage(recce.libmarpa_r)
        bocage.libmarpa_b = b
        setmetatable(bocage, {
                __index = bocage_class,
            })
        return bocage
    end

## Declare the bocage class

    -- luatangle: section Declare bocage_class
    local bocage_class = {}

## Declare the bocage show() method

    -- luatangle: section Declare bocage show() method

    local function or_node_tag(libmarpa_b, or_node_id)
        local irl_id = kollos_c._marpa_b_or_node_irl(libmarpa_b, or_node_id)
        local position = kollos_c._marpa_b_or_node_position(libmarpa_b, or_node_id)
        local or_origin = kollos_c._marpa_b_or_node_origin(libmarpa_b, or_node_id)
        local or_set = kollos_c._marpa_b_or_node_set(libmarpa_b, or_node_id)
        return 'R' .. irl_id .. ':' .. position .. '@' .. or_origin .. '-' .. or_set
    end

    function bocage_class.show(bocage)
        local grammar = bocage.grammar
        local libmarpa_b = bocage.libmarpa_b
        local libmarpa_g = bocage.libmarpa_g
        local or_node_id = 0
        local data = {}
        local tags = {}
        while true do
            local irl_id = kollos_c._marpa_b_or_node_irl(libmarpa_b, or_node_id)
            if not irl_id then break end
            local position = kollos_c._marpa_b_or_node_position(libmarpa_b, or_node_id)
            local or_origin = kollos_c._marpa_b_or_node_origin(libmarpa_b, or_node_id)
            local or_set = kollos_c._marpa_b_or_node_set(libmarpa_b, or_node_id)
            local first_and_node_id
            = kollos_c._marpa_b_or_node_first_and(libmarpa_b, or_node_id)
            local last_and_node_id
            = kollos_c._marpa_b_or_node_last_and(libmarpa_b, or_node_id)
            for and_node_id in first_and_node_id, last_and_node_id do
                local symbol = kollos_c._marpa_b_and_node_symbol(libmarpa_b, and_node_id)
                local cause_tag
                if symbol then cause_tag = 'S' .. symbol end
                local cause_id = kollos_c._marpa_b_and_node_cause(libmarpa_b, and_node_id)
                local cause_irl_id
                if cause_id then
                    cause_irl_id = kollos_c._marpa_b_or_node_irl(libmarpa_b, cause_id)
                    cause_tag = or_node_tag(libmarpa_b, cause_id)
                end
                local parent_tag = or_node_tag(libmarpa_b, or_node_id)
                local predecessor_id = kollos_c._marpa_b_and_node_predecessor(libmarpa_b, or_node_id)
                local predecessor_tag = '-'
                if predecessor_id then
                    local predecessor_tag = or_node_tag(libmarpa_b, predecssor_id)
                end
                local tag =
                and_node_id .. ':'
                .. ' ' .. or_node_id .. '=' .. parent_tag
                .. ' ' .. predecessor_tag
                .. ' ' .. cause_tag
                tags[and_node_id] = tag
                data[#data+1] = and_node_id
            end
            or_node_id = or_node_id + 1
        end
        table.sort(data)
        for data_ix in 1, #data do
            local and_node_id = data[data_ix]
            data[data_ix] = tags[and_node_id]
        end
        return table.concat(data, '\n') .. '\n'
    end

## Finish and return the bocage static class

    -- luatangle: section Finish return object

    local bocage_static_class = {
        new = bocage_new
    }
    return bocage_static_class

## Development errors

    -- luatangle: section Development error methods

    local function development_error_stringize(error_object)
        return
        "bocage error at line "
        .. error_object.line
        .. " of "
        .. error_object.file
        .. ":\n "
        .. error_object.string
    end

    local function development_error(bocage, string)
        local error_object
        = kollos_c.error_new{
            stringize = development_error_stringize,
            code = luif_err_development,
            line = debug.getinfo(2, 'l').short_src,
            line = debug.getinfo(2, 'l').currentline,
            string = string
        }
        if bocage.throw then error(tostring(error_object)) end
        return error_object
    end

## Output file

    -- luatangle: section main

    -- luacheck: std lua51
    -- luacheck: globals bit
    -- luacheck: globals __FILE__ __LINE__

    -- local inspect = require "kollos.inspect"
    local wrap = require "kollos.wrap"

    -- luatangle: insert Declare bocage_class
    -- luatangle: insert Development error methods
    -- luatangle: insert Constructor
    -- luatangle: insert Declare bocage show() method
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
