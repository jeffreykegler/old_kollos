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

    function new(grammar)
        local recce = {
             grammar = grammar,
             throw = grammar.throw,
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

## The start() method

    -- luatangle: section start() recce method

    function recce_class.start(recce)
        local r = recce.libmarpa_r
        return r:start_input()
    end

## Finish and return the recce static class

    -- luatangle: section Finish return object

    recce_static_class = {
        new = new
    }
    return recce_static_class

## Output file

    -- luatangle: section main

    -- luacheck: std lua51
    -- luacheck: globals bit
    -- luacheck: globals __FILE__ __LINE__

    local wrap = require "kollos.wrap"
    local a8lex = require "kollos.a8lex"

    -- luatangle: insert Declare recce_class
    -- luatangle: insert Constructor
    -- luatangle: insert start() recce method
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
