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
    irules = {
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
      { lhs='exp', rhs = { 'e_or_E', 'opt_sign ', 'digit_seq' } },
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
      { lhs='quote', rhs = { 'escape_char', 'quote_char' } },
      { lhs='backslash', rhs = { 'escape_char', 'backslash_char' } },
      { lhs='slash', rhs = { 'escape_char', 'slash_char' } },
      { lhs='backspace', rhs = { 'escape_char', 'letter_b' } },
      { lhs='formfeed', rhs = { 'escape_char', 'letter_f' } },
      { lhs='linefeed', rhs = { 'escape_char', 'letter_n' } },
      { lhs='carriage_return', rhs = { 'escape_char', 'letter_r' } },
      { lhs='tab', rhs = { 'escape_char', 'letter_t' } },
      { lhs='hex_char', rhs = { 'escape_char', 'letter_u', 'hex_digit', 'hex_digit', 'hex_digit', 'hex_digit' } },
      { lhs='simple_string', rhs = { 'escape_char', 'unescaped_char_seq' } },
      { lhs='unescaped_char_seq', rhs = { 'unescaped_char_seq', 'unescaped_char' } },
      { lhs='unescaped_char_seq', rhs = { 'unescaped_char' } }
    },

    symi = {
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
      ['opt_exp'] = {},
      ['opt_frac'] = {},
      ['opt_minus'] = {},
      ['opt_sign'] = {},
      ['unescaped_char_seq'] = {},
      ['ws'] = {},
      ['ws_seq'] = {},
      ['slash_char'] = { charclass = "[\047]" },
      ['backslash_char'] = { charclass = "[\092]" },
      ['escape_char'] = { charclass = "[\092]" },
      ['unescaped_char'] = { charclass = "[ !\035-\091\093-\255]" },
      ['ws_char'] = { charclass = "[\009\010\013\032]" },
      ['lsquare'] = { charclass = "[\091]" },
      ['lcurly'] = { charclass = "[{]" },
      ['hexdigit'] = { charclass = "[%x]" },
      ['rsquare'] = { charclass = "[\093]" },
      ['rcurly'] = { charclass = "[}]" },
      ['colon'] = { charclass = "[:]" },
      ['comma'] = { charclass = "[,]" },
      ['dot'] = { charclass = "[.]" },
      ['quote'] = { charclass = '["]' },
      ['char_zero'] = { charclass = "[0]" },
      ['char_nonzero'] = { charclass = "[1-9]" },
      ['char_digit'] = { charclass = "[0-9]" },
      ['char_minus'] = { charclass = '[-]' },
      ['char_minus'] = { charclass = '[+]' },
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

-- Next we start the database of intermediate KLOL symbols
for k,v in ipairs(json_kir['l0']['irules']) do
    local lhs = v['lhs']
    local rhs = v['rhs']
    for i,rhs_item in ipairs(rhs) do
	lhs_by_rhs[rhs] = lhs
	local rhs_table = rhs_by_lhs[lhs]
	if (rhs_table == nil) then
	  rhs_by_lhs[lhs] = {}
	  rhs_table = rhs_by_lhs[lhs]
	end
	table.insert(rhs_table, lhs)
    end
end

print (kollos_external.table.tostring(rhs_by_lhs))

