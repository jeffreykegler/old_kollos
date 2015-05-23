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

-- luacheck: std lua51
-- luacheck: globals bit

local dumper = require "dumper" -- luacheck: ignore

-- eventually most of this code becomes part of kollos
-- for now we bring the already written part in as a
-- module
local kollos_external = require "kollos"
local _klol = kollos_external._klol

local luif_err_none -- luacheck: ignore
= _klol.error.code['LUIF_ERR_NONE'] -- luacheck: ignore
local luif_err_unexpected_token -- luacheck: ignore
= _klol.error.code['LUIF_ERR_UNEXPECTED_TOKEN_ID'] -- luacheck: ignore

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
  local max_column_word = bit.rshift(dim-1, 5)+1
  for from_ix = 1,dim do
    local from_vector = matrix[from_ix]
    for to_ix = 1,dim do
      local from_word = bit.rshift(from_ix-1, 5)+1
      local from_bit = bit.band(from_ix-1, 0x1F)
      if bit.band(matrix[to_ix][from_word], bit.lshift(1, from_bit)) ~= 0 then
        -- 32 bits at a time -- fast!
        -- in the Luajit, it should pipeline, and be several times faster
        local to_vector = matrix[to_ix]
        for word_ix = 1,max_column_word do
          to_vector[word_ix] = bit.bor(from_vector[word_ix], to_vector[word_ix])
        end
      end
    end
  end
end

local function matrix_init( dim)
  local matrix = {}
  local max_column_word = bit.rshift(dim-1, 5)+1
  for i = 1,dim do
    matrix[i] = {}
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
  local column_word = bit.rshift(column-1, 5)+1
  local column_bit = bit.band(column-1, 0x1F)
  -- print("column_word:", column_word, " column_bit: ", column_bit)
  local bit_vector = matrix[row]
  bit_vector[column_word] = bit.bor(bit_vector[column_word], bit.lshift(1, column_bit))
end

local function matrix_bit_test(matrix, row, column)
  local column_word = bit.rshift(column-1, 5)+1
  local column_bit = bit.band(column-1, 0x1F)
  -- print("column_word:", column_word, " column_bit: ", column_bit)
  return bit.band(matrix[row][column_word], bit.lshift(1, column_bit)) ~= 0
end

--[[

The RHS transitive closure is Jeffrey's coinage, to describe
a kind of property useful in Marpa.

Let `P` be a symbol property.
We will write `P(sym)` if symbol `sym`
has property P.

We say that the symbol property holds of a rule `r`,
or `P(r)`,
if `r` is of the form
`LHS ::= RHS`,
where `RHS` is is a series
of zero or more RHS symbols,
and `P(Rsym)` for every `Rsym` in `RHS`.

A property `P` is *RHS transitive* if and only if
when `r = LHS ::= RHS` and `P(r)`,
then `P(LHS)`.

Note that the definition of a RHS transitive property implies that
every LHS of an empty rule hss that property.
This is because, in the case of an empty rule, it is vacuously
true that all the RHS symbols have the RHS transitive property.

Also note the definition only describes the transitivity of the
property, not which symbols have it.
That is, while `P` is a RHS transitive property,
a symbol must have property `P`
if it appears on the LHS
of a rule with property `P`.
the converse is not necessarily true:
A symbol may have property `P`
even if it never appears on the LHS
of a rule with property `P`.

In Marpa, "being productive" and
"being nullable" are RHS transitive properties
--]]

local function rhs_transitive_closure(symbol_by_name, property)
  local worklist = {}
  for _, symbol_props in pairs(symbol_by_name) do
    if symbol_props[property] == true then
      table.insert(worklist, symbol_props)
    end
  end

  while true do
    local symbol_props = table.remove(worklist)
    if not symbol_props then break end
    -- print("Symbol taken from work list: ", symbol_props.name)
    -- print( dumper.dumper(symbol_props.irule_by_rhs))
    for _,irule_props in pairs(symbol_props.irule_by_rhs) do
      -- print("Start of testing rule for propetry ", property);
      local lh_sym_props = symbol_by_name[irule_props.lhs]
      if lh_sym_props[property] ~= true then
        -- print("Rule LHS: ", lh_sym_props.name)
        local rule_has_property = true -- default to true
        for _,rhs_name in pairs(irule_props.rhs) do
          local rh_sym_props = symbol_by_name[rhs_name]
          -- print("Rule RHS symbol: ", rh_sym_props.name)
          if not rh_sym_props[property] then
            rule_has_property = false
            break
          end
        end
        -- print("End of testing rule, result = ", rule_has_property);
        if rule_has_property then
          -- we don't get here if the LHS symbol already
          -- has the property, so no symbol is ever
          -- put on worklist twice
          lh_sym_props[property] = true
          -- print("Setting property ", property, " true for symbol ", lh_sym_props.name, " from ", symbol_props.name)
          table.insert(worklist, lh_sym_props)
        end
      end

    end
  end
end

-- We leave the KIR as is, and work with
-- intermediate databases

-- currently grammar is unused, but someday we may need the grammar name
local function do_grammar(grammar, properties) -- luacheck: ignore grammar

  -- I expect to handle cycles eventually, so this logic must be
  -- cycle-safe.

  local g_is_structural = properties.structural

  -- while developing we do all the "hygenic" tests to
  -- make sure the KIR is sane

  -- In production, the KIR will be produced by Kollos's
  -- own logic, so this boolean should only be set
  -- for debugging
  local hygenic = true -- luacheck: ignore hygenic

  -- Next we start the database of intermediate KLOL symbols
  local symbol_by_name = {} -- create an symbol to integer index
  local symbol_by_id = {} -- create an integer to symbol index
  local klol_rules = {} -- an array of the KLOL rules

  local function klol_symbol_new(props)
    props.lhs_by_rhs = {}
    props.rhs_by_lhs = {}
    props.irule_by_rhs = {}
    props.irule_by_lhs = {}
    symbol_by_name[props.name] = props
    local symbol_id = #symbol_by_id+1
    props.id = symbol_id
    symbol_by_id[symbol_id] = props
    return props
  end

  --[[ COMMENTED OUT
  -- clone a null symbol from a proper
  -- nullable and make the original bulky
  local function klol_null_new(nullable_symbol)
    local null_variant = klol_symbol_new{
      name = (nullable_symbol.name .. '?null'),
      isym_props = nullable_symbol.isym_props,
      bulk_variant = nullable_symbol,
      nullable = true,
      nulling = true,
      productive = true
    }
    nullable_symbol.null_variant = null_variant
    nullable_symbol.nullable = false
    return null_variant
  end
  --]]

  local function klol_rule_new(rule_props)
    klol_rules[ #klol_rules + 1 ] = rule_props

    --[[ COMMENTED OUT
    local rule_desc = rule_props.lhs.symbol.name .. ' ::='
    for dot_ix = 1,#rule_props.rhs do
      -- print( "rule_props.rhs", dumper.dumper(rule_props.rhs))
      rule_desc = rule_desc .. ' ' .. rule_props.rhs[dot_ix].symbol.name
    end
    print("KLOL rule:", rule_desc)
    --]]

  end

  local top_symbol -- will be RHS of augmented start rule

  -- a pseudo-symbol "reached" by all terminals
  -- for convenience in determinal if a symbol reaches any terminal
  local sink_terminal = klol_symbol_new{ name = '?sink_terminal', productive = true}
  local augment_symbol = klol_symbol_new{ name = '?augment'}

  if (not g_is_structural) then
    top_symbol = klol_symbol_new{ name = '?top'}
  end

  for symbol_name,isym_props in pairs(properties.isym) do
    local symbol_props = klol_symbol_new{ isym_props = isym_props, name = symbol_name,
      is_khil = true -- true if a KHIL symbol
    }
    if (isym_props.charclass) then
      symbol_props.productive = true;
      symbol_props.terminal = true;
      symbol_props.nullable = false;
    end
    if (isym_props.lexeme) then
      if (g_is_structural) then
        error('Internal error: Lexeme "' .. symbol_name .. '" declared in structural grammar')
      end
      symbol_props.lexeme = true;
    end
    if (isym_props.start) then
      if (not g_is_structural) then
        error('Internal error: Start symbol "' .. symbol_name '" declared in lexical grammar')
      end
      top_symbol = symbol_props
    end
  end

  if (not top_symbol) then
    error('Internal error: No start symbol found in grammar')
  end

  for rule_ix,irule_props in ipairs(properties.irule) do
    local lhs_name = irule_props.lhs
    local lhs_props = symbol_by_name[lhs_name]
    if (not lhs_props) then
      error("Internal error: Symbol " .. lhs_name .. " is lhs of irule but not in isym")
    end
    lhs_props.irule_by_lhs[#lhs_props.irule_by_lhs+1] = irule_props
    local rhs_names = irule_props.rhs
    if (#rhs_names == 0) then
      lhs_props.nullable = true
      lhs_props.productive = true
    end
    for _,rhs_name in ipairs(rhs_names) do
      local rhs_props = symbol_by_name[rhs_name]
      if (not rhs_props) then
        error("Internal error: Symbol " .. rhs_name .. " is rhs of irule but not in isym")
      end

      -- built different from irule_by_lhs, because symbols
      -- may occur several times on the RHS
      rhs_props.irule_by_rhs[rule_ix] = irule_props

      rhs_props.lhs_by_rhs[lhs_name] = lhs_props
      lhs_props.rhs_by_lhs[rhs_name] = rhs_props
    end
  end

  for symbol_name,symbol_props in pairs(symbol_by_name) do
    if (not symbol_props.lhs_by_rhs and not symbol_props.rhs_by_lhs and symbol_props.is_khil) then
      error("Internal error: Symbol " .. symbol_name .. " is in isym but not in irule")
    end
    if (symbol_props.charclass and #symbol_props.irule_by_lhs > 0) then
      error("Internal error: Symbol " .. symbol_name .. " has charclass but is on LHS of irule")
    end
  end

  -- now set up the reach matrix
  local reach_matrix = matrix_init(#symbol_by_id)
  if not g_is_structural then
    matrix_bit_set(reach_matrix, augment_symbol.id, top_symbol.id)
  end

  for symbol_id,symbol_props in ipairs(symbol_by_id) do
    local isym_props = symbol_props.isym_props
    -- every symbol reaches itself
    matrix_bit_set(reach_matrix, symbol_id, symbol_id)
    if isym_props then
      for _,lhs_props in pairs(symbol_props.lhs_by_rhs) do
        matrix_bit_set(reach_matrix, lhs_props.id, symbol_id)
      end
      if symbol_props.terminal then
        matrix_bit_set(reach_matrix, symbol_id, sink_terminal.id)
      end
      if symbol_props.lexeme then
        matrix_bit_set(reach_matrix, top_symbol.id, symbol_id)
      end
    end
  end

  transitive_closure(reach_matrix)

  rhs_transitive_closure(symbol_by_name, 'nullable')
  rhs_transitive_closure(symbol_by_name, 'productive')

  --[[
  I don't want to get into adding the KLOL rules until later, so for
  a lexical grammar we mark the top symbol productive to silence the
  error message. We will test that all the lexemes were productive,
  and that is sufficient.
  --]]

  if not g_is_structural then
    top_symbol.productive = true
  end

  for symbol_id,symbol_props in ipairs(symbol_by_id) do
    if not matrix_bit_test(reach_matrix, augment_symbol.id, symbol_id) then
      print("Symbol " .. symbol_props.name .. " is not accessible")
    end
    if not symbol_props.productive then
      print("Symbol " .. symbol_props.name .. " is not productive")
    end
    if symbol_props.nullable and
    not matrix_bit_test(reach_matrix, symbol_id, sink_terminal.id)
    then symbol_props.nulling = true end
    if symbol_props.lexeme then
      if symbol_props.nulling then
        print("Symbol " .. symbol_props.name .. " is a nulling lexeme -- A FATAL ERROR")
      end
      if not symbol_props.productive then
        print("Symbol " .. symbol_props.name .. " is an unproductive lexeme -- A FATAL ERROR")
      end
    end

  end

  --[[ COMMENTED OUT
  for from_symbol_id,from_symbol_props in ipairs(symbol_by_id) do
    for to_symbol_id,to_symbol_props in ipairs(symbol_by_id) do
      if matrix_bit_test(reach_matrix, from_symbol_id, to_symbol_id) then
        print( from_symbol_props.name, "reaches", to_symbol_props.name)
      end
    end
  end
  --]]

  if top_symbol.nulling then
    print("Start symbol " .. top_symbol.name .. " is nulling -- NOT YET IMPLEMENTED SPECIAL CASE")
  end

  -- we do not need to traverse symbols to symbol_by_id
  for ix = 1,#symbol_by_id do
    local symbol_props = symbol_by_id[ix]
    if symbol_props.nullable and not symbol_props.nulling then
      print("Symbol " .. symbol_props.name .. " is proper nullable")
      klol_symbol_new(symbol_props)
    end
  end

  local unique_number = 1 -- used in forming names of symbols

  for _,irule_props in ipairs(properties.irule) do
    local lh_sym_name = irule_props.lhs
    local lh_sym_props = symbol_by_name[lh_sym_name]
    local rhs_names = irule_props.rhs
    local instance_stack = {}
    for dot_ix,rhs_name in ipairs(rhs_names) do
      local rh_sym_props = symbol_by_name[rhs_name]

      -- skip nulling symbols
      -- the span and dot info is a prototype of the kind
      -- of information about location in the xrule that
      -- I will need to reconstruct the external rule,
      -- and to do the semantics
      if not rh_sym_props.nulling then
        local instance = {
          kir_dot = dot_ix,
          symbol = rh_sym_props
        }
        instance_stack[#instance_stack + 1] = instance
      end
    end

    local start_of_nullable_suffix = #instance_stack+1
    for i=#instance_stack,1,-1 do
      if not instance_stack[i].symbol.nullable then break end
      start_of_nullable_suffix = i
    end

    -- first LHS is that of the original rule
    local lh_sides = {}
    lh_sides[1] = {
      irule = irule_props,
      kir_dot = 1,
      symbol = lh_sym_props
    }
    -- we need a new LHS for the length of the original
    -- RHS, less 2
    for instance_ix=2,#instance_stack-1 do
      local new_lhs_name =
      irule_props.lhs .. '?' .. unique_number .. '@' .. instance_ix
      unique_number = unique_number + 1
      local new_lh_symbol = klol_symbol_new{ name = new_lhs_name }
      lh_sides[#lh_sides+1] = {
        irule = irule_props,
        kir_dot = instance_stack[instance_ix].kir_dot,
        symbol = new_lh_symbol
      }
    end

    -- if the rule is empty (zero length) it will
    -- "fall through" the following logic
    local next_rule_base = 1
    while #instance_stack - next_rule_base >= 2 do
      local new_rule_lhs = lh_sides[next_rule_base]
      local rhs_instance_1 = instance_stack[next_rule_base]
      local next_lhs = lh_sides[next_rule_base+1]
      klol_rule_new{
        lhs = new_rule_lhs,
        rhs = { rhs_instance_1, next_lhs }
      }
      if start_of_nullable_suffix <= next_rule_base+1 then
        klol_rule_new{
          lhs = new_rule_lhs,
          rhs = { rhs_instance_1 }
        }
      end
      if rhs_instance_1.symbol.nullable then
        klol_rule_new{
          lhs = new_rule_lhs,
          rhs = { next_lhs }
        }
      end
      next_rule_base = next_rule_base+1
    end

    -- If two RHS instances remain ...
    if #instance_stack - next_rule_base == 1 then
      local new_rule_lhs = lh_sides[next_rule_base]
      local rhs_instance_1 = instance_stack[next_rule_base]
      local rhs_instance_2 = instance_stack[next_rule_base+1]
      klol_rule_new{
        lhs = new_rule_lhs,
        rhs = { rhs_instance_1, rhs_instance_2 }
      }

      -- order by symbol used on the RHS,
      -- not by symbol tested so that
      -- the output is easier to read
      if rhs_instance_2.symbol.nullable then
        klol_rule_new{
          lhs = new_rule_lhs,
          rhs = { rhs_instance_1 }
        }
      end

      if rhs_instance_1.symbol.nullable then
        klol_rule_new{
          lhs = new_rule_lhs,
          rhs = { rhs_instance_2 }
        }
      end
    end

    -- If one RHS instance remains ...
    if #instance_stack - next_rule_base == 0 then
      local new_rule_lhs = lh_sides[next_rule_base]
      local rhs_instance_1 = instance_stack[next_rule_base]
      klol_rule_new{
        lhs = new_rule_lhs, rhs = { rhs_instance_1 }
      }
    end

  end -- of for _,irule_props in ipairs(properties.irule)

  -- now create additional rules ...
  -- first the augment rule
  -- do not yet know what to do about location information
  -- for instances
  klol_rule_new{
    lhs = { symbol = augment_symbol },
    rhs = { { symbol = top_symbol } }
  }

  -- and now deal with the lexemes ...
  -- which will only be present in a lexical grammar ...
  -- we need to create the "lexeme prefix symbols"
  -- and to add rules which connect them to the
  -- top symbol
  for _,symbol_props in ipairs(symbol_by_id) do
    if symbol_props.lexeme then
      local lexeme_prefix = klol_symbol_new{ name = symbol_props.name .. '?prelex' }
      klol_rule_new{
        lhs = { symbol = top_symbol },
        rhs = {
          { symbol = lexeme_prefix },
          { symbol = symbol_props },
        }
      }
    end
  end

  local g = _klol.grammar()
  local symbol_by_libmarpa_id = {}
  for _,symbol_props in ipairs(symbol_by_id) do
    local libmarpa_id = g:symbol_new()
    symbol_by_libmarpa_id[libmarpa_id] = symbol_props
    symbol_props.libmarpa_id = libmarpa_id
  end

  for _,rule_props in pairs(klol_rules) do
    local lhs_libmarpa_id = rule_props.lhs.symbol.libmarpa_id
    local rhs1_libmarpa_id = rule_props.rhs[1].symbol.libmarpa_id
    local rhs2_libmarpa_id = rule_props.rhs[2] and
      rule_props.rhs[2].symbol.libmarpa_id
    local libmarpa_rule_id = g:rule_new( lhs_libmarpa_id,
      rhs1_libmarpa_id, rhs2_libmarpa_id)
    rule_props.libmarpa_rule_id = libmarpa_rule_id
  end

  g:start_symbol_set(augment_symbol.libmarpa_id)
  g:precompute()

  local r = _klol.recce(g)
  r:start_input()

--[[ NOT YET IMPLEMENTED
local result = r:alternative(prefix, 1, 1) -- luacheck: ignore result
result = r:earleme_complete() -- luacheck: ignore result

while r:is_exhausted() ~= 1 do
  result = r:alternative(a, 1, 1)
  if (not result) then
    -- print("reached earley set " .. r:latest_earley_set())
    break
  end
  result = r:earleme_complete()
  if (result < 0) then
    error("result of earleme_complete = " .. result)
  end
end
--]]

  return {}

end

local klog_g_l0 = do_grammar('l0', json_kir['l0']) -- luacheck: ignore klog_g_l0

-- vim: expandtab shiftwidth=4:
