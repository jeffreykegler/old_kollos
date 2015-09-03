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

# Kollos "mid-level" value code

This is the code for the "middle layer" values
of Kollos.
Below it is Libmarpa, a library written in
the C language which contains the actual parse engine.

## Constructor

    -- luatangle: section Constructor

    local function value_new(tree)
        local grammar = tree.grammar
        local value = {
            _type = "value",
            grammar = grammar,
            throw = tree.throw,
        }

        value = kollos_c.value_new(value, tree)
        setmetatable(value, {
                __index = value_class,
            })
        return value
    end

## Declare the value class

    -- luatangle: section declare value_class
    local value_class = {}

## Finish and return the value static class

    -- luatangle: section Finish return object

    local value_static_class = {
        new = value_new
    }
    return value_static_class

## Development errors

    -- luatangle: section Development error methods

    local function development_error_stringize(error_object)
        return
        "value error at line "
        .. error_object.line
        .. " of "
        .. error_object.file
        .. ":\n "
        .. error_object.string
    end

    local function development_error(value, string)
        local error_object
        = kollos_c.error_new{
            stringize = development_error_stringize,
            code = luif_err_development,
            line = debug.getinfo(2, 'l').short_src,
            line = debug.getinfo(2, 'l').currentline,
            string = string
        }
        if value.throw then error(tostring(error_object)) end
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

    -- luatangle: insert declare value_class

    for k,v in pairs(kollos_c) do
         if k:match('^[_]?value') then
             local c_wrapper_name = k:gsub('value', '', 1)
             value_class[c_wrapper_name] = v
         end
    end

    -- luatangle: insert Development error methods
    -- luatangle: insert Constructor
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
