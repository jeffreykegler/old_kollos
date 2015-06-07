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

require 'Test.More'
plan(1)

-- luacheck: std lua51
-- luacheck: globals bit

local function here() return -- luacheck: ignore here
    debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
end

local inspect = require "kollos.inspect" -- luacheck: ignore
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

ok(1, 'reached end')

-- vim: expandtab shiftwidth=4:
