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

local kollos_c = require 'kollos_c'

-- The Libmarpa wrapper layer
local wrap = { }

-- make certain useful error codes more visible
local luif_err_none = kollos_c.error_code_by_name['LUIF_ERR_NONE']
local luif_err_unexpected_token = kollos_c.error_code_by_name['LUIF_ERR_UNEXPECTED_TOKEN_ID']

local grammar_class  = {
  ["rule_new"] = kollos_c.grammar_rule_new,
  ["completion_symbol_activate"] = kollos_c.grammar_completion_symbol_activate,
  ["error"] = kollos_c.grammar_error,
  ["error_clear"] = kollos_c.grammar_error_clear,
  ["event"] = kollos_c.grammar_event,
  ["events"] = kollos_c.grammar_events,
  ["event_count"] = kollos_c.grammar_event_count,
  ["force_valued"] = kollos_c.grammar_force_valued,
  ["has_cycle"] = kollos_c.grammar_has_cycle,
  ["highest_rule_id"] = kollos_c.grammar_highest_rule_id,
  ["highest_symbol_id"] = kollos_c.grammar_highest_symbol_id,
  ["is_precomputed"] = kollos_c.grammar_is_precomputed,
  ["nulled_symbol_activate"] = kollos_c.grammar_nulled_symbol_activate,
  ["precompute"] = kollos_c.grammar_precompute,
  ["prediction_symbol_activate"] = kollos_c.grammar_prediction_symbol_activate,
  ["rule_is_accessible"] = kollos_c.grammar_rule_is_accessible,
  ["rule_is_loop"] = kollos_c.grammar_rule_is_loop,
  ["rule_is_nullable"] = kollos_c.grammar_rule_is_nullable,
  ["rule_is_nulling"] = kollos_c.grammar_rule_is_nulling,
  ["rule_is_productive"] = kollos_c.grammar_rule_is_productive,
  ["rule_is_proper_separation"] = kollos_c.grammar_rule_is_proper_separation,
  ["rule_length"] = kollos_c.grammar_rule_length,
  ["rule_lhs"] = kollos_c.grammar_rule_lhs,
  ["rule_null_high"] = kollos_c.grammar_rule_null_high,
  ["rule_null_high_set"] = kollos_c.grammar_rule_null_high_set,
  ["rule_rhs"] = kollos_c.grammar_rule_rhs,
  ["sequence_min"] = kollos_c.grammar_sequence_min,
  ["sequence_separator"] = kollos_c.grammar_sequence_separator,
  ["start_symbol"] = kollos_c.grammar_start_symbol,
  ["start_symbol_set"] = kollos_c.grammar_start_symbol_set,
  ["symbol_is_accessible"] = kollos_c.grammar_symbol_is_accessible,
  ["symbol_is_completion_event"] = kollos_c.grammar_symbol_is_completion_event,
  ["symbol_is_completion_event_set"] = kollos_c.grammar_symbol_is_completion_event_set,
  ["symbol_is_counted"] = kollos_c.grammar_symbol_is_counted,
  ["symbol_is_nullable"] = kollos_c.grammar_symbol_is_nullable,
  ["symbol_is_nulled_event"] = kollos_c.grammar_symbol_is_nulled_event,
  ["symbol_is_nulled_event_set"] = kollos_c.grammar_symbol_is_nulled_event_set,
  ["symbol_is_nulling"] = kollos_c.grammar_symbol_is_nulling,
  ["symbol_is_prediction_event"] = kollos_c.grammar_symbol_is_prediction_event,
  ["symbol_is_prediction_event_set"] = kollos_c.grammar_symbol_is_prediction_event_set,
  ["symbol_is_productive"] = kollos_c.grammar_symbol_is_productive,
  ["symbol_is_start"] = kollos_c.grammar_symbol_is_start,
  ["symbol_is_terminal"] = kollos_c.grammar_symbol_is_terminal,
  ["symbol_is_terminal_set"] = kollos_c.grammar_symbol_is_terminal_set,
  ["symbol_is_valued"] = kollos_c.grammar_symbol_is_valued,
  ["symbol_is_valued_set"] = kollos_c.grammar_symbol_is_valued_set,
  ["symbol_new"] = kollos_c.grammar_symbol_new,
  ["zwa_new"] = kollos_c.grammar_zwa_new,
  ["zwa_place"] = kollos_c.grammar_zwa_place,
}

function wrap.grammar()
  local grammar_object = kollos_c.grammar_new(
      { _type = "grammar", throw = true }
  )
  setmetatable(grammar_object, {
      __index = grammar_class,
  })
  return grammar_object
end

local recce_class  = {
  ["completion_symbol_activate"] = kollos_c.recce_completion_symbol_activate,
  ["current_earleme"] = kollos_c.recce_current_earleme,
  ["earleme_complete"] = kollos_c.recce_earleme_complete,
  ["earleme"] = kollos_c.recce_earleme,
  ["earley_item_warning_threshold"] = kollos_c.recce_earley_item_warning_threshold,
  ["earley_item_warning_threshold_set"] = kollos_c.recce_earley_item_warning_threshold_set,
  ["earley_set_value"] = kollos_c.recce_earley_set_value,
  ["expected_symbol_event_set"] = kollos_c.recce_expected_symbol_event_set,
  ["furthest_earleme"] = kollos_c.recce_furthest_earleme,
  ["is_exhausted"] = kollos_c.recce_is_exhausted,
  ["latest_earley_set"] = kollos_c.recce_latest_earley_set,
  ["latest_earley_set_value_set"] = kollos_c.recce_latest_earley_set_value_set,
  ["nulled_symbol_activate"] = kollos_c.recce_nulled_symbol_activate,
  ["prediction_symbol_activate"] = kollos_c.recce_prediction_symbol_activate,
  ["progress_item"] = kollos_c.recce_progress_item,
  ["progress_report_finish"] = kollos_c.recce_progress_report_finish,
  ["progress_report_start"] = kollos_c.recce_progress_report_start,
  ["start_input"] = kollos_c.recce_start_input,
  ["terminal_is_expected"] = kollos_c.recce_terminal_is_expected,
  ["zwa_default"] = kollos_c.recce_zwa_default,
  ["zwa_default_set"] = kollos_c.recce_zwa_default_set,
}

function recce_class.alternative(recce, symbol)
    -- print("alternative(", recce, symbol, ")")
    local result = kollos_c.recce_alternative(recce, symbol, 1, 1)
    if (result == luif_err_unexpected_token) then return nil end
    if (result == luif_err_none) then return 1 end
    kollos_c.error_throw(result, "alternative()");
end

function wrap.recce(grammar_object)
  local recce_object = kollos_c.recce_new(
      { _type = "recce", throw = grammar_object.throw },
      grammar_object
  )
  setmetatable(recce_object, {
      __index = recce_class,
  })
  return recce_object
end

return wrap

-- vim: expandtab shiftwidth=4:
