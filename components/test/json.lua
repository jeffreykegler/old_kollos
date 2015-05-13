-- eventually merge this code into the kollos module
-- for now, we include it to get various utility methods
local kollos_external = require "kollos"
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
      { lhs='begin_object', rhs = { 'ws', 'lsquare', 'ws' }},
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
      { lhs='decimal_point', rhs = { dot }},
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
      ['decimal_point'] = {},
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
      ['hex_digit'] = { charclass = '[0-9a-fA-F]' },
      ['ws_char'] = { charclass = "[\009\010\013\032]" },
      ['lsquare'] = { charclass = "[\091]" },
      ['lcurly'] = { charclass = "[{]" },
      ['hexdigit'] = { charclass = "[%x]" },
      ['rsquare'] = { charclass = "[\093]" },
      ['rcurly'] = { charclass = "[}]" },
      ['colon'] = { charclass = "[:]" },
      ['comma'] = { charclass = "[,]" },
      ['dot'] = { charclass = "[.]" },
      ['char_quote'] = { charclass = '["]' },
      ['char_zero'] = { charclass = "[0]" },
      ['char_nonzero'] = { charclass = "[1-9]" },
      ['char_digit'] = { charclass = "[0-9]" },
      ['char_minus'] = { charclass = '[-]' },
      ['char_plus'] = { charclass = '[+]' },
      ['char_a'] = { charclass = "[a]" },
      ['char_b'] = { charclass = "[b]" },
      ['char_E'] = { charclass = "[E]" },
      ['char_e'] = { charclass = "[e]" },
      ['char_i'] = { charclass = "[i]" },
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

-- We leave the KIR as is, and work with
-- intermediate databases

local lhs_by_rhs = {}
local rhs_by_lhs = {}
local lhs_rule_by_rhs = {}
local rhs_rule_by_lhs = {}
local sym_is_nulling = {}
local sym_is_productive = {}
local sym_is_seen = {}

for symbol,v in pairs(json_kir['l0']['isym']) do
  lhs_by_rhs[symbol] = {}
  rhs_by_lhs[symbol] = {}
  lhs_rule_by_rhs[symbol] = {}
  rhs_rule_by_lhs[symbol] = {}
end

-- Next we start the database of intermediate KLOL symbols
for rule_ix,v in ipairs(json_kir['l0']['irule']) do
  local lhs = v['lhs']
  if (not lhs_by_rhs[lhs]) then
    error("Internal error: Symbol " .. lhs .. " is lhs of irule but not in isym")
  end
  table.insert(rhs_rule_by_lhs[lhs], rule_ix);
  local rhs = v['rhs']
  if (#rhs == 0){
      sym_is_nullable[lhs] = true;
      sym_is_productive[lhs] = true;
  }
  for dot_ix,rhs_item in ipairs(rhs) do
    if (not lhs_by_rhs[rhs_item]) then
      error("Internal error: Symbol " .. rhs_item .. " is rhs of irule but not in isym")
    end
    table.insert(lhs_rule_by_rhs[rhs_item], rule_ix);
    lhs_by_rhs[rhs_item][lhs] = true;
    rhs_by_lhs[lhs][rhs_item] = true;
  end
end

local sym_is_productive = {}
local sym_is_seen = {}

for symbol,v in pairs(json_kir['l0']['isym']) do
  if (not lhs_by_rhs[symbol] and not rhs_by_lhs[symbol]) then
    error("Internal error: Symbol " .. symbol .. " is in isym but not in irule")
  end
  if (v[charclass]) then
      sym_is_seeable[symbol] = true;
      sym_is_productive[symbol] = true;
  end
end

-- I expect to handle cycles eventually, so this logic must be
-- cycle-safe.

print (dumper.dumper(rhs_by_lhs))

-- vim: expandtab shiftwidth=4:
