-- luacheck: std lua51

require 'Test.More'
plan(1)

local kollos_external = require "kollos"
local wrap = kollos_external.wrap

local luif_err_none -- luacheck: ignore
  = kollos_external.error.code_by_name['LUIF_ERR_NONE'] -- luacheck: ignore
local luif_err_unexpected_token -- luacheck: ignore
  = kollos_external.error.code_by_name['LUIF_ERR_UNEXPECTED_TOKEN_ID'] -- luacheck: ignore

local g = wrap.grammar()
local top = g:symbol_new()
local seq = g:symbol_new()
local item = g:symbol_new()
local prefix = g:symbol_new()
local body = g:symbol_new()
local a = g:symbol_new()
local start_rule = g:rule_new(top, seq) -- luacheck: ignore
local seq_rule1 = g:rule_new(seq, item) -- luacheck: ignore
local seq_rule2 = g:rule_new(seq, seq, item) -- luacheck: ignore
local item_rule = g:rule_new(item, prefix, body) -- luacheck: ignore
local body_rule = g:rule_new(body, a, a) -- luacheck: ignore
g:start_symbol_set(top)
g:precompute()

local r = wrap.recce(g)
r:start_input()

local pass_count = 0
local max_pass = arg[1] or 10000
for _ = 1,max_pass do

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
  pass_count = pass_count + 1;

end

is(pass_count, 10000, 'pass count')

