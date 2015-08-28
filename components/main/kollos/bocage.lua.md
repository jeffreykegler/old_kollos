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
            _type = "bocage",
            grammar = grammar,
            throw = recce.throw,
        }

        bocage = kollos_c.bocage_new(bocage,
            recce,
            symbol,
            start_loc,
            end_loc
        )
        setmetatable(bocage, {
                __index = bocage_class,
            })
        return bocage
    end

## Declare the bocage class

    -- luatangle: section declare bocage_class
    local bocage_class = {}

## Declare the bocage show() method

    -- luatangle: section declare bocage show() method

    local function or_node_tag(bocage, or_node_id)
        local irl_id = bocage:__or_node_irl(or_node_id)
        local position = bocage:__or_node_position(or_node_id)
        local or_origin = bocage:__or_node_origin(or_node_id)
        local or_set = bocage:__or_node_set(or_node_id)
        return 'R' .. irl_id .. ':' .. position .. '@' .. or_origin .. '-' .. or_set
    end

    function and_node_tag(bocage, and_node_id)
        local parent_or_node_id = bocage:__and_node_parent(and_node_id)
        local origin_loc = bocage:__or_node_origin(parent_or_node_id)
        local current_loc = bocage:__or_node_set(parent_or_node_id)
        local cause_or_id        = bocage:__and_node_cause(and_node_id)
        local predecessor_or_id = bocage:__and_node_predecessor(and_node_id)
        local middle_loc = bocage:__and_node_middle(and_node_id)
        local loc = bocage:__or_node_position(parent_or_node_id)
        local irl_id = bocage:__or_node_irl(parent_or_node_id)
        local pieces = {
              'R', irl_id, ':', loc, '@',
            origin_loc, '-', current_loc
        }
        if cause_or_id then
            pieces[#pieces+1] = 'C' ..  bocage:__or_node_irl(cause_or_id)
        else
            pieces[#pieces+1] = 'S' .. bocage:__and_node_symbol(and_node_id)
        end
        pieces[#pieces+1] = '@' .. middle_loc
        return table.concat(pieces)
    end

    function bocage_class.show(bocage)
        local or_node_id = 0
        local data = {}
        local tags = {}
        while true do
            local irl_id = bocage:__or_node_irl(or_node_id)
            if not irl_id then break end
            local first_and_node_id
                = bocage:__or_node_first_and(or_node_id)
            local last_and_node_id
                = bocage:__or_node_last_and(or_node_id)
            for and_node_id = first_and_node_id, last_and_node_id do
                local symbol = bocage:__and_node_symbol(and_node_id)
                local cause_tag
                if symbol then cause_tag = 'S' .. symbol end
                local cause_id = bocage:__and_node_cause(and_node_id)
                if cause_id then
                    cause_tag = or_node_tag(bocage, cause_id)
                end
                local parent_tag = or_node_tag(bocage, or_node_id)
                local predecessor_id = bocage:__and_node_predecessor(or_node_id)
                local predecessor_tag = '-'
                if predecessor_id then
                    predecessor_tag = or_node_tag(bocage, predecessor_id)
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
        for data_ix = 1, #data do
            local and_node_id = data[data_ix]
            data[data_ix] = tags[and_node_id]
        end
        return table.concat(data, '\n') .. '\n'
    end

## Bocage and_nodes_show() method

    -- luatangle: section declare bocage _and_nodes_show() method

    function bocage_class._and_nodes_show(bocage)
        local and_node_data = {}
        local and_node_id = 0
        while true do
            local origin = bocage:__and_node_origin(and_node_id)
            if not origin then break end
            local schwartzian = { and_node_id, origin,
                bocage:__and_node_set(and_node_id),
                bocage:__and_node_irl(and_node_id),
                bocage:__and_node_position(and_node_id),
                bocage:__and_node_middle(and_node_id),
                bocage:__and_node_cause(and_node_id),
                (bocage:__and_node_symbol(and_node_id) or -1)
            }
            and_node_id = and_node_id+1
            -- array index of and_node_id is and_node_id+1
            -- so we use and_node_id *post-increment*
            and_node_data[and_node_id] = schwartzian
        end
        table.sort(and_node_data, schwartz_cmp)
        local pieces = {}
        for ix = 1, #and_node_data do
            pieces[ix] = and_node_tag(bocage, and_node_data[ix][1])
        end
        return table.concat(pieces)
    end

```

# The bocage _or_nodes_show() method

The nodes are not sorted and therefore the
output is not suitable for use in a test suite.

    -- luatangle: section declare bocage _or_nodes_show() method

    local function or_node_show(bocage, or_node_id, verbose)
        local origin = bocage:__or_node_origin(or_node_id)
        local grammar = bocage.grammar
        if not origin then return end
        local current_set_id = bocage:__or_node_set(or_node_id)
        local irl_id = bocage:__or_node_irl(or_node_id)
        local position = bocage:__or_node_position(or_node_id)
        local pieces = {
              "OR-node #" .. or_node_id .. ': '
            .. or_node_tag(bocage, or_node_id)
        }
        local first_and_node_id
            = bocage:__or_node_first_and(or_node_id)
        local last_and_node_id
            = bocage:__or_node_last_and(or_node_id)
        local and_node_count = (last_and_node_id - first_and_node_id) + 1
        pieces[#pieces+1] = ', ' .. and_node_count .. ' ands: '
        local display_and_node_count = and_node_count > 5 and 5 or and_node_count
        local and_descs = {}
        for ix = 1,display_and_node_count do
              and_descs[#and_descs+1] = and_node_tag(bocage, first_and_node_id + ix - 1)
        end
        table.sort(and_descs)
        if display_and_node_count < and_node_count then
              and_descs[#and_descs+1] = '...'
        end
        pieces[#pieces+1] = table.concat(and_descs, ' ') .. '\n'
        if verbose then
            pieces[#pieces+1] = "    "
            .. grammar:show_dotted_irl(irl_id, position)
            .. '\n'
        end
        return table.concat(pieces)
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
    local kollos_c = require "kollos_c"
    local util = require "kollos.util"
    local schwartz_cmp = util.schwartz_cmp
    local luif_err_development = kollos_c.error_code_by_name['LUIF_ERR_DEVELOPMENT']

    -- luatangle: insert declare bocage_class

    for k,v in pairs(kollos_c) do
         if k:match('^[_]?bocage') then
             local c_wrapper_name = k:gsub('bocage', '', 1)
             bocage_class[c_wrapper_name] = v
         end
    end

    -- luatangle: insert Development error methods
    -- luatangle: insert Constructor
    -- luatangle: insert declare bocage show() method
    -- luatangle: insert declare bocage _and_nodes_show() method
    -- luatangle: insert declare bocage _or_nodes_show() method
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
