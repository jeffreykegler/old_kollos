-- Copyright 2015 Jeffrey Kegler
-- This file is part of Marpa::R2.  Marpa::R2 is free software: you can
-- redistribute it and/or modify it under the terms of the GNU Lesser
-- General Public License as published by the Free Software Foundation,
-- either version 3 of the License, or (at your option) any later version.
--
-- Marpa::R2 is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser
-- General Public License along with Marpa::R2.  If not, see
-- http://www.gnu.org/licenses/.

local function c_type_of_libmarpa_type(libmarpa_type)
    if (libmarpa_type == 'int') then return 'int' end
    if (libmarpa_type == 'Marpa_Assertion_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_IRL_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_NSY_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_Or_Node_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_And_Node_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_Rank') then return 'int' end
    if (libmarpa_type == 'Marpa_Rule_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_Symbol_ID') then return 'int' end
    if (libmarpa_type == 'Marpa_Earley_Set_ID') then return 'int' end
    return "!UNIMPLEMENTED!";
end

local class_type = {
  g = "Marpa_Grammar",
  r = "Marpa_Recognizer",
  b = "Marpa_Bocage",
  o = "Marpa_Order",
  t = "Marpa_Tree",
  v = "Marpa_Value",
};

local c_fn_signatures = {
  {"marpa_g_completion_symbol_activate", "Marpa_Symbol_ID", "sym_id", "int", "activate"},
  {"marpa_g_error_clear"},
  {"marpa_g_event_count"},
  {"marpa_g_force_valued"},
  {"marpa_g_has_cycle"},
  {"marpa_g_highest_rule_id"},
  {"marpa_g_highest_symbol_id"},
  {"marpa_g_is_precomputed"},
  {"marpa_g_nulled_symbol_activate", "Marpa_Symbol_ID", "sym_id", "int", "activate"},
  {"marpa_g_precompute"},
  {"marpa_g_prediction_symbol_activate", "Marpa_Symbol_ID", "sym_id", "int", "activate"},
  {"marpa_g_rule_is_accessible", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_is_loop", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_is_nullable", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_is_nulling", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_is_productive", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_is_proper_separation", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_length", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_lhs", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_null_high", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_rule_null_high_set", "Marpa_Rule_ID", "rule_id", "int", "flag"},
  {"marpa_g_rule_rhs", "Marpa_Rule_ID", "rule_id", "int", "ix"},
  {"marpa_g_sequence_min", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_sequence_separator", "Marpa_Rule_ID", "rule_id"},
  {"marpa_g_start_symbol"},
  {"marpa_g_start_symbol_set", "Marpa_Symbol_ID", "id"},
  {"marpa_g_symbol_is_accessible", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_completion_event", "Marpa_Symbol_ID", "sym_id"},
  {"marpa_g_symbol_is_completion_event_set", "Marpa_Symbol_ID", "sym_id", "int", "value"},
  {"marpa_g_symbol_is_counted", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_nullable", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_nulled_event", "Marpa_Symbol_ID", "sym_id"},
  {"marpa_g_symbol_is_nulled_event_set", "Marpa_Symbol_ID", "sym_id", "int", "value"},
  {"marpa_g_symbol_is_nulling", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_prediction_event", "Marpa_Symbol_ID", "sym_id"},
  {"marpa_g_symbol_is_prediction_event_set", "Marpa_Symbol_ID", "sym_id", "int", "value"},
  {"marpa_g_symbol_is_productive", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_start", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_terminal", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_terminal_set", "Marpa_Symbol_ID", "symbol_id", "int", "boolean"},
  {"marpa_g_symbol_is_valued", "Marpa_Symbol_ID", "symbol_id"},
  {"marpa_g_symbol_is_valued_set", "Marpa_Symbol_ID", "symbol_id", "int", "boolean"},
  {"marpa_g_symbol_new"},
  {"marpa_g_zwa_new", "int", "default_value"},
  {"marpa_g_zwa_place", "Marpa_Assertion_ID", "zwaid", "Marpa_Rule_ID", "xrl_id", "int", "rhs_ix"},
  {"marpa_r_completion_symbol_activate", "Marpa_Symbol_ID", "sym_id", "int", "reactivate"},
  {"marpa_r_current_earleme"},
  {"marpa_r_earleme", "Marpa_Earley_Set_ID", "ordinal"},
  {"marpa_r_earleme_complete"},
  {"marpa_r_earley_item_warning_threshold"},
  {"marpa_r_earley_item_warning_threshold_set", "int", "too_many_earley_items"},
  {"marpa_r_earley_set_value", "Marpa_Earley_Set_ID", "ordinal"},
  {"marpa_r_expected_symbol_event_set", "Marpa_Symbol_ID", "xsyid", "int", "value"},
  {"marpa_r_furthest_earleme"},
  {"marpa_r_is_exhausted"},
  {"marpa_r_latest_earley_set"},
  {"marpa_r_latest_earley_set_value_set", "int", "value"},
  {"marpa_r_nulled_symbol_activate", "Marpa_Symbol_ID", "sym_id", "int", "reactivate"},
  {"marpa_r_prediction_symbol_activate", "Marpa_Symbol_ID", "sym_id", "int", "reactivate"},
  {"marpa_r_progress_report_finish"},
  {"marpa_r_progress_report_start", "Marpa_Earley_Set_ID", "ordinal"},
  {"marpa_r_terminal_is_expected", "Marpa_Symbol_ID", "xsyid"},
  {"marpa_r_zwa_default", "Marpa_Assertion_ID", "zwaid"},
  {"marpa_r_zwa_default_set", "Marpa_Assertion_ID", "zwaid", "int", "default_value"},
  {"marpa_b_ambiguity_metric"},
  {"marpa_b_is_null"},
  {"marpa_o_ambiguity_metric"},
  {"marpa_o_high_rank_only_set", "int", "flag"},
  {"marpa_o_high_rank_only"},
  {"marpa_o_is_null"},
  {"marpa_o_rank"},
  {"marpa_t_next"},
  {"marpa_t_parse_count"},
  {"marpa_v_valued_force"},
  {"marpa_v_rule_is_valued_set", "Marpa_Rule_ID", "symbol_id", "int", "value"},
  {"marpa_v_symbol_is_valued_set", "Marpa_Symbol_ID", "symbol_id", "int", "value"},
  {"_marpa_g_rule_is_keep_separation", "Marpa_Rule_ID", "rule_id"},
  {"_marpa_g_irl_lhs", "Marpa_IRL_ID", "rule_id"},
  {"_marpa_g_irl_rhs", "Marpa_IRL_ID", "rule_id", "int", "ix"},
  {"_marpa_g_irl_length", "Marpa_IRL_ID", "rule_id"},
  {"_marpa_g_irl_rank", "Marpa_IRL_ID", "irl_id"},
  {"_marpa_g_nsy_rank", "Marpa_NSY_ID", "nsy_id"},
  {"_marpa_g_nsy_is_semantic", "Marpa_NSY_ID", "nsy_id"},
  {"_marpa_b_and_node_cause", "Marpa_And_Node_ID", "ordinal"},
  {"_marpa_b_and_node_count"},
  {"_marpa_b_and_node_middle", "Marpa_And_Node_ID", "and_node_id"},
  {"_marpa_b_and_node_parent", "Marpa_And_Node_ID", "and_node_id"},
  {"_marpa_b_and_node_predecessor", "Marpa_And_Node_ID", "ordinal"},
  {"_marpa_b_and_node_symbol", "Marpa_And_Node_ID", "and_node_id"},
  {"_marpa_b_or_node_and_count", "Marpa_Or_Node_ID", "or_node_id"},
  {"_marpa_b_or_node_first_and", "Marpa_Or_Node_ID", "ordinal"},
  {"_marpa_b_or_node_irl", "Marpa_Or_Node_ID", "ordinal"},
  {"_marpa_b_or_node_is_semantic", "Marpa_Or_Node_ID", "or_node_id"},
  {"_marpa_b_or_node_is_whole", "Marpa_Or_Node_ID", "or_node_id"},
  {"_marpa_b_or_node_last_and", "Marpa_Or_Node_ID", "ordinal"},
  {"_marpa_b_or_node_origin", "Marpa_Or_Node_ID", "ordinal"},
  {"_marpa_b_or_node_position", "Marpa_Or_Node_ID", "ordinal"},
  {"_marpa_b_or_node_set", "Marpa_Or_Node_ID", "ordinal"},
  {"_marpa_b_top_or_node"},
}

io.write([=[
#define LUA_LIB
#include "marpa.h"
#include "lua.h"
#include "lauxlib.h"

#include "compat-5.2.c"

void kollos_throw(lua_State* L,
    lua_Number code, const char* details);

]=])

local check_for_table_template = [=[
!!INDENT!!if (!lua_istable (L, 1))
!!INDENT!! {
!!INDENT!!    luaL_error (L,
!!INDENT!!       "!!FUNCNAME!!() expected table as arg #1, got ",
!!INDENT!!       lua_typename (L, lua_type (L, 1)));
!!INDENT!!  }
]=]

-- automatically generate wrappers
--   this code is only safe if all of the following are true:
--   1.) The number of arguments is fixed.
--   2.) Their type is from a fixed list.
--   3.) Converting the return value to int is a good thing to do.
--   4.) Non-negatvie return values indicate success
--   5.) Return values less than -1 indicate failure
--   6.) Return values less than -1 set the error code
--   7.) Return value of -1 is "soft" and returning nil is
--       the right thing to do
for ix = 1, #c_fn_signatures do
   local signature = c_fn_signatures[ix]
   local arg_count = math.floor(#signature/2)
   local function_name = signature[1]
   local unprefixed_name = string.gsub(function_name, "^[_]?marpa_", "");
   class_letter = string.gsub(unprefixed_name, "_.*$", "");
   -- print( class_letter )
   local wrapper_name = "wrap_" .. unprefixed_name;
   io.write("static int ", wrapper_name, "(lua_State *L)\n");
   io.write("{\n");
   io.write("  ", class_type[class_letter], " self;\n");
   io.write("  Marpa_Grammar grammar;\n");
   local arg_ix = 2;
   for arg_ix = 1, arg_count do
     local arg_type = signature[arg_ix*2]
     local arg_name = signature[1 + arg_ix*2]
     io.write("  ", arg_type, " ", arg_name, ";\n");
   end
   io.write("  int result;\n\n");

   -- These wrappers will not be external interfaces
   -- so eventually they will run unsafe.
   -- But for now we check arguments, and we'll leave
   -- the possibility for debugging
   local safe = true;
   if (safe) then
      io.write("  if (1) {\n")

      local check_for_table =
           string.gsub(check_for_table_template, "!!FUNCNAME!!", wrapper_name);
      check_for_table =
           string.gsub(check_for_table, "!!INDENT!!", "    ");
      io.write(check_for_table);
      -- I do not get the values from the integer checks,
      -- because this code
      -- will be turned off most of the time
      for arg_ix = 1, arg_count do
          io.write("    luaL_checkint(L, ", (arg_ix+1), ");\n")
      end
      io.write("  }\n");
   end -- if (!unsafe)

   for arg_ix = 1, arg_count do
     local arg_type = signature[arg_ix*2]
     local arg_name = signature[1 + arg_ix*2]
     local c_type = c_type_of_libmarpa_type(arg_type)
     assert(c_type == "int", ("type " .. c_type .. "not implemented"))
     io.write("  ", arg_name, " = lua_tointeger(L, -1);\n")
     io.write("  lua_pop(L, 1);\n")
   end

   io.write('  lua_getfield (L, -1, "_ud");\n')
   -- stack is [ self, self_ud ]
   local cast_to_ptr_to_class_type = "(" ..  class_type[class_letter] .. "*)"
   io.write("  self = *", cast_to_ptr_to_class_type, "lua_touserdata (L, -1);\n")
   -- stack is [ self ]

   io.write('  lua_getfield (L, -1, "_g_ud");\n')
   -- stack is [ self, grammar_ud ]
   io.write("  grammar = *(Marpa_Grammar*)lua_touserdata (L, -1);\n")
   -- stack is [ self ]

   -- assumes converting result to int is safe and right thing to do
   -- if that assumption is wrong, generate the wrapper by hand
   io.write("  result = (int)", function_name, "(self\n")
   for arg_ix = 1, arg_count do
     local arg_name = signature[1 + arg_ix*2]
     io.write("     ,", arg_name, "\n")
   end
   io.write("    );\n")
   io.write("  if (result == -1) { lua_pushnil(L); return 1; }\n")
   io.write("  if (result < -1) {\n")
   io.write("    Marpa_Error_Code marpa_error = marpa_g_error(grammar, NULL);\n")
   local wrapper_name_as_c_string = '"' .. wrapper_name .. '()"'
   io.write('    kollos_throw( L, marpa_error, ', wrapper_name_as_c_string, ');\n')
   io.write("  }\n")
   io.write("  lua_pushinteger(L, (lua_Integer)result);\n")
   io.write("  return 1;\n")
   io.write("}\n\n");
end

-- static int l_grammar_start_symbol_set(lua_State *L)
-- {
--     Marpa_Grammar *p_g;
--     Marpa_Symbol_ID start_symbol;
--     Marpa_Symbol_ID result;
--     /* [ grammar_object, start_symbol ] */
--
--     /* This will not be an external interface,
--      * so eventually we will run unsafe.
--      * This checking code is for debugging.
--      */
--
--     start_symbol = (Marpa_Symbol_ID)lua_tointeger(L, -1);
--     lua_pop(L, 1);
--     /* [ grammar_object ] */
--
--     lua_getfield (L, -1, "_ud");
--     /* [ grammar_object, grammar_ud ] */
--     p_g = (Marpa_Grammar *) lua_touserdata (L, -1);
--     result = marpa_g_start_symbol_set(*p_g, start_symbol);
--     if (result < -1) {
--         Marpa_Error_Code marpa_error = marpa_g_error(*p_g, NULL);
--         kollos_throw( L, marpa_error, "marpa_g_start_symbol_set()" );
--     }
--     lua_pushinteger(L, (lua_Integer)result);
--     return 1;
-- }
--
-- vim: expandtab shiftwidth=4:
