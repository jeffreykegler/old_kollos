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

The Kollos low level grammar logic

--]]

-- luacheck: std lua51
-- luacheck: globals bit

local inspect = require "kollos.inspect" -- luacheck: ignore

--[[

This next function uses Warshall's algorithm. This is slower in theory
but uses bitops, memory and pipelining well. Grune & Jacob claim that
arc-by-arc method is better but it needs a work list, and that means
recursion or memory management of a stack, which can easily slow things
down by a factor of 10 or more.

Of course, this is always the possibility of porting my C code, which is
Warshall's in optimized pure C, but I suspect the LuaJIT is just as good.

Function summary: Given a transition matrix, which is a table of tables
such that matrix[a][b] is true if there is a transition from a to b,
change it into its closure

--]]

local matrix = {}

function matrix.transitive_closure(matrix_arg)
    -- as an efficiency hack, we store the
    -- from, to duples as two entries, so
    -- that we don't have to create a table
    -- for each duple
    local dim = #matrix_arg
    local max_column_word = bit.rshift(dim-1, 5)+1
    for from_ix = 1,dim do
        local from_vector = matrix_arg[from_ix]
        for to_ix = 1,dim do
            local from_word = bit.rshift(from_ix-1, 5)+1
            local from_bit = bit.band(from_ix-1, 0x1F)
            if bit.band(matrix_arg[to_ix][from_word], bit.lshift(1, from_bit)) ~= 0 then
                -- 32 bits at a time -- fast!
                -- in the Luajit, it should pipeline, and be several times faster
                local to_vector = matrix_arg[to_ix]
                for word_ix = 1,max_column_word do
                    to_vector[word_ix] = bit.bor(from_vector[word_ix], to_vector[word_ix])
                end
            end
        end
    end
end

function matrix.init( dim)
    local new_matrix = {}
    local max_column_word = bit.rshift(dim-1, 5)+1
    for i = 1,dim do
        new_matrix[i] = {}
        for j = 1,max_column_word do
            new_matrix[i][j] = 0
        end
    end
    return new_matrix
end

--[[
In the matrices, I give in to Lua's conventions --
everything is 1-based. Except, of course, bit position.
In Pall's 32-bit vectors, that is 0-based.
--]]
function matrix.bit_set(matrix_arg, row, column)
    local column_word = bit.rshift(column-1, 5)+1
    local column_bit = bit.band(column-1, 0x1F)
    -- print("column_word:", column_word, " column_bit: ", column_bit)
    local bit_vector = matrix_arg[row]
    bit_vector[column_word] = bit.bor(bit_vector[column_word], bit.lshift(1, column_bit))
end

function matrix.bit_test(matrix_arg, row, column)
    local column_word = bit.rshift(column-1, 5)+1
    local column_bit = bit.band(column-1, 0x1F)
    -- print("column_word:", column_word, " column_bit: ", column_bit)
    return bit.band(matrix_arg[row][column_word], bit.lshift(1, column_bit)) ~= 0
end

return matrix

-- vim: expandtab shiftwidth=4:
