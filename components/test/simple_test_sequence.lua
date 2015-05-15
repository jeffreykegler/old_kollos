local kollos_external = require "kollos"
local _klol = kollos_external._klol

luif_err_none = _klol.error.code['LUIF_ERR_NONE']
luif_err_unexpected_token = _klol.error.code['LUIF_ERR_UNEXPECTED_TOKEN_ID']

g = _klol.grammar()

top = g:symbol_new()

seq = g:symbol_new()
item = g:symbol_new()
separator = g:symbol_new()

start_rule = g:rule_new(top, seq)
seq_rule = g:sequence_new(seq, item, separator, 0, 0)

if (seq_rule < 0) then
  error("result of sequence_new = " .. seq_rule)
end

g:start_symbol_set(top)
g:precompute()

input = { item, separator, item, separator, item, separator, item, separator }
r = _klol.recce(g)
r:start_input()

for i = 1, #input do
  result = r:alternative(input[i], 1, 1)
  if (not result) then
    -- print("reached earley set " .. r:latest_earley_set())
    break
  end
  result = r:earleme_complete()
  if (result < 0) then
    error("result of earleme_complete = " .. result)
  end
end

g = nil
r = nil
