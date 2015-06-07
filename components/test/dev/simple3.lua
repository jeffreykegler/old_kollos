--[[

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

--]]

--[[

The primary aim of this parser is to test Kollos as a platform for
arbitrary grammars. Speed is also an aim, but secondary.

In keeping with these priorities, JSON is treated as if there were no
existing code for it -- after all, if I wanted a fast JSON parser I could
just grab a very fast C language recursive descent parser from somewhere.
Everything is created "from scratch" using tools which generalize to
other parsers. For example, I'm sure there is code out there in both
Lua and C to crunch JSON strings, code which is both better and faster
than what is here, but I do not use it.

--]]

-- luacheck: std lua51
-- luacheck: globals bit

local function here() return -- luacheck: ignore here
    debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
end

local inspect = require "kollos.inspect" -- luacheck: ignore

-- eventually most of this code becomes part of kollos
-- for now we bring the already written part in as a
-- module
local kollos = require "kollos"

local test_kir =
{

    test4xA = {
        irule = {
            { lhs='top', rhs={ 'A', 'B', 'C', 'D' } },
            { lhs='A', rhs={ } },
            { lhs='B', rhs={ } },
            { lhs='C', rhs={ } },
            { lhs='D', rhs={ } },
            { lhs='A', rhs={ 'char_a' } },
            { lhs='B', rhs={ 'char_a' } },
            { lhs='C', rhs={ 'char_a' } },
            { lhs='D', rhs={ 'char_a' } },
        },

        isym = {
            ['top'] = { lexeme = true },
            ['A'] = {},
            ['B'] = {},
            ['C'] = {},
            ['D'] = {},
            ['char_a'] = { charclass = "[a]" },
        }
    },

    test2_nul = {
        irule = {
            { lhs='top', rhs={ 'A', 'B', 'C', 'nul', 'nul' } },
            { lhs='A', rhs={ } },
            { lhs='B', rhs={ } },
            { lhs='nul', rhs={ } },
            { lhs='A', rhs={ 'char_a' } },
            { lhs='B', rhs={ 'char_a' } },
            { lhs='C', rhs={ 'char_a' } },
        },

        isym = {
            ['top'] = { lexeme = true },
            ['A'] = {},
            ['B'] = {},
            ['C'] = {},
            ['nul'] = {},
            ['char_a'] = { charclass = "[a]" },
        }
    },

    mid_nulling = {
        irule = {
            { lhs='top', rhs={ 'A', 'B', 'C', 'D', 'nul' } },
            { lhs='A', rhs={ } },
            { lhs='C', rhs={ } },
            { lhs='D', rhs={ } },
            { lhs='nul', rhs={ } },
            { lhs='A', rhs={ 'char_a' } },
            { lhs='B', rhs={ 'char_a' } },
            { lhs='D', rhs={ 'char_a' } },
        },

        isym = {
            ['top'] = { lexeme = true },
            ['A'] = {},
            ['B'] = {},
            ['C'] = {},
            ['D'] = {},
            ['nul'] = {},
            ['char_a'] = { charclass = "[a]" },
        }

    },
}

kollos.lo_g.kir_compile(test_kir)

-- vim: expandtab shiftwidth=4:
