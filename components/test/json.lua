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

-- eventually merge this code into the kollos module
-- for now, we include it when we get various utility methods
-- local kollos_external = require "kollos"

local dumper = require "dumper"

local json_kir =
{
  -- tokens in l0 are at a lower level than
  -- "tokens" as defined in RFC 7159, section 2
  -- RFC 7159 does not separate semantics from syntax --
  -- if you assume either top-down parsing (as in recursive
  -- descent) or a dedicated lexer (as in yacc) there's no
  -- need to make the separation.
  l0 = {
    irule = {
      -- ws before and after <value>, see RFC 7159, section 2
      { lhs='ws_before', rhs={ 'ws' } },
      { lhs='ws_after', rhs={ 'ws' } },
      -- next rules are ws ::= ws_char*
      { lhs='ws', rhs={ 'ws_seq' } },
      { lhs='ws_seq', rhs={ 'ws_seq', 'ws_char' } },
      { lhs='ws_seq', rhs={ 'ws_char' } },
      { lhs='ws_seq', rhs={ } }, -- empty
      { lhs='begin_array', rhs = { 'ws', 'lsquare', 'ws' } },
      { lhs='begin_object', rhs = { 'ws', 'lcurly', 'ws' }},
      { lhs='end_array', rhs = { 'ws', 'rsquare', 'ws' }},
      { lhs='end_object', rhs = { 'ws', 'rcurly', 'ws' }},
      { lhs='name_separator', rhs = { 'ws', 'colon', 'ws' }},
      { lhs='value_separator', rhs = { 'ws', 'comma', 'ws' }},
      { lhs='false', rhs = { 'char_f', 'char_a', 'char_l', 'char_s', 'char_e' }},
      { lhs='true', rhs = { 'char_t', 'char_r', 'char_u', 'char_e' }},
      { lhs='null', rhs = { 'char_n', 'char_u', 'char_l', 'char_l' }},
      { lhs='minus', rhs = { 'char_minus' }},

      -- Lua number format seems to be compatible with JSON,
      -- so we treat a JSON number as a full token
      { lhs='number', rhs = { 'opt_minus', 'int', 'opt_frac', 'opt_exp' }},
      { lhs='opt_minus', rhs = { 'char_minus' } },
      { lhs='opt_minus', rhs = { } },
      { lhs='opt_exp', rhs = { 'exp' } },
      { lhs='opt_exp', rhs = { } },
      { lhs='exp', rhs = { 'e_or_E', 'opt_sign', 'digit_seq' } },
      { lhs='e_or_E', rhs = { 'char_e' } },
      { lhs='e_or_E', rhs = { 'char_E' } },
      { lhs='opt_sign', rhs = { } },
      { lhs='opt_sign', rhs = { 'char_minus' } },
      { lhs='opt_sign', rhs = { 'char_plus' } },
      { lhs='opt_frac', rhs = { } },
      { lhs='opt_frac', rhs = { 'frac' } },
      { lhs='frac', rhs = { 'dot', 'digit_seq' } },
      { lhs='int', rhs = { 'char_nonzero', 'digit_seq' } },
      { lhs='digit_seq', rhs = { 'digit_seq', 'char_digit' } },
      { lhs='digit_seq', rhs = { 'char_digit' } },

      -- we divide up the standards string token, because we
      -- need to do semantic processing on its pieces
      { lhs='quote', rhs = { 'char_escape', 'char_quote' } },
      { lhs='backslash', rhs = { 'char_escape', 'char_backslash' } },
      { lhs='slash', rhs = { 'char_escape', 'char_slash' } },
      { lhs='backspace', rhs = { 'char_escape', 'char_b' } },
      { lhs='formfeed', rhs = { 'char_escape', 'char_f' } },
      { lhs='linefeed', rhs = { 'char_escape', 'char_n' } },
      { lhs='carriage_return', rhs = { 'char_escape', 'char_r' } },
      { lhs='tab', rhs = { 'char_escape', 'char_t' } },
      { lhs='hex_char', rhs = { 'char_escape', 'char_u', 'hex_digit', 'hex_digit', 'hex_digit', 'hex_digit' } },
      { lhs='simple_string', rhs = { 'char_escape', 'unescaped_char_seq' } },
      { lhs='unescaped_char_seq', rhs = { 'unescaped_char_seq', 'unescaped_char' } },
      { lhs='unescaped_char_seq', rhs = { 'unescaped_char' } }
    },

    isym = {
      ['ws_before'] = { lexeme = true },
      ['ws_after'] = { lexeme = true },
      ['begin_array'] = { lexeme = true },
      ['begin_object'] = { lexeme = true },
      ['end_array'] = { lexeme = true },
      ['end_object'] = { lexeme = true },
      ['name_separator'] = { lexeme = true },
      ['value_separator'] = { lexeme = true },
      ['false'] = { lexeme = true },
      ['true'] = { lexeme = true },
      ['null'] = { lexeme = true },
      ['minus'] = { lexeme = true },
      ['number'] = { lexeme = true },
      ['quote'] = { lexeme = true },
      ['backslash'] = { lexeme = true },
      ['slash'] = { lexeme = true },
      ['backspace'] = { lexeme = true },
      ['formfeed'] = { lexeme = true },
      ['linefeed'] = { lexeme = true },
      ['carriage_return'] = { lexeme = true },
      ['tab'] = { lexeme = true },
      ['hex_char'] = { lexeme = true },
      ['simple_string'] = { lexeme = true },
      ['digit_seq'] = {},
      ['exp'] = {},
      ['frac'] = {},
      ['int'] = {},
      ['e_or_E'] = {},
      ['opt_exp'] = {},
      ['opt_frac'] = {},
      ['opt_minus'] = {},
      ['opt_sign'] = {},
      ['unescaped_char_seq'] = {},
      ['ws'] = {},
      ['ws_seq'] = {},
      ['char_slash'] = { charclass = "[\047]" },
      ['char_backslash'] = { charclass = "[\092]" },
      ['char_escape'] = { charclass = "[\092]" },
      ['unescaped_char'] = { charclass = "[ !\035-\091\093-\255]" },
      ['ws_char'] = { charclass = "[\009\010\013\032]" },
      ['lsquare'] = { charclass = "[\091]" },
      ['lcurly'] = { charclass = "[{]" },
      ['hex_digit'] = { charclass = "[%x]" },
      ['rsquare'] = { charclass = "[\093]" },
      ['rcurly'] = { charclass = "[}]" },
      ['colon'] = { charclass = "[:]" },
      ['comma'] = { charclass = "[,]" },
      ['dot'] = { charclass = "[.]" },
      ['char_quote'] = { charclass = '["]' },
      ['char_nonzero'] = { charclass = "[1-9]" },
      ['char_digit'] = { charclass = "[0-9]" },
      ['char_minus'] = { charclass = '[-]' },
      ['char_plus'] = { charclass = '[+]' },
      ['char_a'] = { charclass = "[a]" },
      ['char_b'] = { charclass = "[b]" },
      ['char_E'] = { charclass = "[E]" },
      ['char_e'] = { charclass = "[e]" },
      ['char_f'] = { charclass = "[f]" },
      ['char_l'] = { charclass = "[l]" },
      ['char_n'] = { charclass = "[n]" },
      ['char_r'] = { charclass = "[r]" },
      ['char_s'] = { charclass = "[s]" },
      ['char_t'] = { charclass = "[t]" },
      ['char_u'] = { charclass = "[u]" },
    }

  },
}

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

local function transitive_closure(matrix)
  -- as an efficiency hack, we store the
  -- from, to duples as two entries, so
  -- that we don't have to create a table
  -- for each duple
  local dim = #matrix
  for from_ix = 1,dim do
    local from_vector = matrix[from_ix]
    for to_ix = 1,dim do
      local to_word = bit.rshift(to_ix, 5)+1
      local to_bit = bit.band(to_ix, 0x1F) -- 0-based
      if bit.band(matrix[from_ix][to_word], bit.lshift(1, to_bit)) ~= 0 then
        -- 32 bits at a time -- fast!
        -- in the Luajit, it should pipeline, and be several times faster
        local to_vector = matrix[to_ix]
        for word_ix = 1,bit.rshift(dim-1, 5)+1 do
          from_vector[word_ix] = bit.band(from_vector[word_ix], to_vector[word_ix])
        end
      end
    end
  end
end

local function matrix_init( dim)
  local matrix = {}
  for i = 1,dim do
    matrix[i] = {}
    local max_column_word = bit.rshift(dim-1, 5)+1
    for j = 1,max_column_word do
      matrix[i][j] = 0
    end
  end
  return matrix
end

--[[
In the matrices, I give in to Lua's conventions --
everything is 1-based. Except, of course, bit position.
In Pall's 32-bit vectors, that is 0-based.
--]]
local function matrix_bit_set(matrix, row, column)
  local column_word = bit.rshift(column, 5)+1
  local column_bit = bit.band(column, 0x1F) -- 0-based
  print("column_word:", column_word, " column_bit: ", column_bit)
  local bit_vector = matrix[row]
  bit_vector[column_word] = bit.bor(bit_vector[column_word], bit.lshift(1, column_bit))
end

local function matrix_bit_test(matrix, row, column)
  local column_word = bit.rshift(column, 5)+1
  local column_bit = bit.band(column, 0x1F) -- 0-based
  print("column_word:", column_word, " column_bit: ", column_bit)
  return bit.band(matrix[row][column_word], bit.lshift(1, column_bit)) ~= 0
end

-- We leave the KIR as is, and work with
-- intermediate databases

local function do_grammar(grammar, properties)

  local g_is_structural = properties.structural

  -- Next we start the database of intermediate KLOL symbols
  local symbol_by_name = {} -- create an symbol to integer index
  local symbol_by_id = {} -- create an integer to symbol index
  local augment_symbol -- will be LHS of augmented start rule
  local top_symbol -- will be RHS of augmented start rule

  -- a pseudo-symbol "reached" by all terminals
  -- for convenience in determinal if a symbol reaches any terminal
  local sink_symbol

  -- I expect to handle cycles eventually, so this logic must be
  -- cycle-safe.

  do
    -- a pseudo-symbol, used to make it easy to find out
    -- if another symbol reaches any terminal
    sink_terminal = { name = '?sink_terminal'}
    table.insert(symbol_by_id, sink_terminal)
    symbol_by_name[sink_terminal.name] = sink_terminal

    -- the augmented start symbol
    augment_symbol = { name = '?augment'}
    table.insert(symbol_by_id, augment_symbol)
    symbol_by_name[augment_symbol.name] = augment_symbol

    if (not g_is_structural) then
      -- a lexical grammar needs a top symbol
      -- as the RHS of its augmented start rule
      top = { name = '?top'}
      table.insert(symbol_by_id, top)
      symbol_by_name[top.name] = top
      top_symbol = top
    end

  end

  -- set up some default fields
  for symbol_id,symbol_props in pairs(symbol_by_id) do
    symbol_props.id = symbol_id
    symbol_props.lhs_by_rhs = {}
    symbol_props.rhs_by_lhs = {}
    symbol_props.irule_by_rhs = {}
    symbol_props.irule_by_lhs = {}
  end

  for symbol_name,isym_props in pairs(properties.isym) do
    local entry = { isym_props = isym_props, name = symbol_name,
      lhs_by_rhs = {},
      rhs_by_lhs = {},
      irule_by_rhs = {},
      irule_by_lhs = {},
      is_khil = true -- true if a KHIL symbol
    }
    table.insert(symbol_by_id, entry)
    symbol_by_name[symbol_name] = entry
    entry.id = #symbol_by_id
    if (isym_props.char_class) then
      entry.productive = true;
      entry.terminal = true;
      entry.nullable = false;
    end
    if (isym_props.lexeme) then
      if (g_is_structural) then
        error('Internal error: Lexeme "' .. symbol .. '" declared in structural grammar')
      end
      entry.lexeme = true;
    end
    if (isym_props.start) then
      if (not g_is_structural) then
        error('Internal error: Start symboisym_props "' .. symbol '" declared in lexical grammar')
      end
      top_symbol = symbol
    end
  end

  if (not top_symbol) then
    error('Internal error: No start symbol found in grammar')
  end

  for rule_ix,irule_props in ipairs(properties.irule) do
    local lhs_name = irule_props.lhs
    local lhs_props = symbol_by_name[lhs_name]
    if (not lhs_props) then
      error("Internal error: Symbol " .. lhs .. " is lhs of irule but not in isym")
    end
    table.insert(lhs_props.irule_by_lhs, irule_props)
    local rhs_names = irule_props.rhs
    if (#rhs_names == 0) then
      lhs_props.nullable = true
      lhs_props.productive = true
    end
    for dot_ix,rhs_name in ipairs(rhs_names) do
      local rhs_props = symbol_by_name[rhs_name]
      if (not rhs_props) then
        error("Internal error: Symbol " .. rhs_item .. " is rhs of irule but not in isym")
      end
      table.insert(rhs_props.irule_by_rhs, irule_props)
      rhs_props.lhs_by_rhs[lhs_name] = lhs_props
      lhs_props.rhs_by_lhs[rhs_name] = rhs_props
    end
  end

  for symbol_name,symbol_props in pairs(symbol_by_name) do
    if (not symbol_props[lhs_by_rhs] and not symbol_props[rhs_by_lhs] and symbol_props[is_khil]) then
      error("Internal error: Symbol " .. symbol .. " is in isym but not in irule")
    end
    if (symbol_props['charclass'] and symbol_props[#irule_by_lhs] > 0) then
      error("Internal error: Symbol " .. symbol_name .. " has charclass but is on LHS of irule")
    end
  end

  -- now set up the reach matrix
  local reach_matrix = matrix_init(#symbol_by_id)
  if not g_is_structural then
      matrix_bit_set(reach_matrix, augment_symbol.id, top_symbol.id)
  end
  for symbol_id,symbol_props in ipairs(symbol_by_id) do
      local symi_props = symbol_props.symi_props
      if symi_props then
           for lhs_name,lhs_props in symbol_props.lhs_by_rhs do
              matrix_bit_set(reach_matrix, lhs_props.id, symbol_id)
           end
           if symbol_props.terminal then
              matrix_bit_set(reach_matrix, symbol_id, sink_terminal.id)
           end
           if symbol_props.lexeme then
              matrix_bit_set(reach_matrix, top.symbol.id, symbol_id)
           end
      end
  end
  transitive_closure(reach_matrix)

end

-- local reach_matrix = matrix_init(43)
-- matrix_bit_set(reach_matrix, 42, 7)
-- print (matrix_bit_test(reach_matrix, 41, 6))
-- print (matrix_bit_test(reach_matrix, 42, 6))
-- print (matrix_bit_test(reach_matrix, 42, 7))
-- print (matrix_bit_test(reach_matrix, 42, 8))
-- print (matrix_bit_test(reach_matrix, 43, 7))
-- matrix_bit_set(reach_matrix, 7, 42)
-- print (matrix_bit_test(reach_matrix, 6, 30))
-- print (matrix_bit_test(reach_matrix, 6, 31))
-- print (matrix_bit_test(reach_matrix, 7, 32))
-- print (matrix_bit_test(reach_matrix, 8, 33))
-- print (matrix_bit_test(reach_matrix, 7, 34))
-- transitive_closure(reach_matrix)

for grammar,properties in pairs(json_kir) do
  do_grammar(grammar, properties)
end

-- vim: expandtab shiftwidth=4:
