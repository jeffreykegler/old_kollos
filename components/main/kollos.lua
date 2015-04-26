-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]

local kollos_c = require "kollos_c"

local _khil = {
  error =  {
    name = kollos_c.error_name,
    description = kollos_c.error_description,
    code = kollos_c.error_code,
  }
}

local grammar_class  = {
    ["rule_new"] = kollos_c.grammar_rule_new,
    ["precompute"] = kollos_c.grammar_precompute,
    ["start_symbol_set"] = kollos_c.grammar_start_symbol_set,
    ["symbol_new"] = kollos_c.grammar_symbol_new,
}

local recce_class  = {
    ["alternative"] = kollos_c.recce_alternative,
    ["earleme_complete"] = kollos_c.recce_earleme_complete,
    ["start_input"] = kollos_c.recce_start_input,
}

function _khil.grammar()
  local grammar_object = kollos_c.grammar_new(
      { _type = "grammar" }
  )
  setmetatable(grammar_object, {
      __index = grammar_class,
  })
  return grammar_object
end

function _khil.recce(grammar_object)
  local recce_object = kollos_c.recce_new(
      { _type = "recce" },
      grammar_object
  )
  setmetatable(recce_object, {
      __index = recce_class,
  })
  return recce_object
end

return { ["_khil"] =_khil }

-- vim: expandtab shiftwidth=4:
