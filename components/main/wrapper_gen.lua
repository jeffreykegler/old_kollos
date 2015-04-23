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

-- my %format_by_type = (
--    int => '%d',
--    Marpa_Assertion_ID => '%d',
--    Marpa_IRL_ID => '%d',
--    Marpa_NSY_ID => '%d',
--    Marpa_Or_Node_ID => '%d',
--    Marpa_And_Node_ID => '%d',
--    Marpa_Rank => '%d',
--    Marpa_Rule_ID => '%d',
--    Marpa_Symbol_ID => '%d',
--    Marpa_Earley_Set_ID => '%d',
--"],
-- 
-- sub gp_generate {
--     my ( $function, @arg_type_pairs ) = "],
--     my $output = q"],
-- 
--     # For example, 'g_wrapper'
--     my $wrapper_variable = $main::CLASS_LETTER . '_wrappe"],
-- 
--     # For example, 'G_Wrapper'
--     my $wrapper_type = ( uc $main::CLASS_LETTER ) . '_Wrappe"],
-- 
--     # For example, 'g_wrapper'
--     my $libmarpa_method =
--           $function =~ m/^_marpa_/xms
--         ? $function
--         : 'marpa_' . $main::CLASS_LETTER . '_' . $functi"],
-- 
--     # Just g_wrapper for the grammar, self->base otherwise
--     my $base = $main::CLASS_LETTER eq 'g' ? 'g_wrapper' : "$wrapper_variable->bas"],
-- 
--     $output .= "void\"],
--     my @args = "],
--     ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
--         push @args, $arg_type_pairs[ $i + 1"],
--     }
--     $output
--         .= "$function( " . ( join q{, }, $wrapper_variable, @args ) . " )\"],
--     $output .= "    $wrapper_type *$wrapper_variable;\"],
--     ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
--         $output .= q{   "],
--         $output .= join q{ }, @arg_type_pairs[ $i .. $i + 1"],
--         $output .= ";\"],
--     }
--     $output .= "PPCODE:\"],
--     $output .= "{\"],
--     $output
--         .= "  $main::LIBMARPA_CLASS self = $wrapper_variable->$main::CLASS_LETTER;\"],
--     $output .= "  int gp_result = $libmarpa_method("
--         . ( join q{, }, 'self', @args ) . ");\"],
--     $output .= "  if ( gp_result == -1 ) { XSRETURN_UNDEF; }\"],
--     $output .= "  if ( gp_result < 0 && $base->throw ) {\"],
--     my @format    = "],
--     my @variables = "],
--     ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
--         my $arg_type = $arg_type_pairs[$"],
--         my $variable = $arg_type_pairs[ $i + 1"],
--         if ( my $format = $format_by_type{$arg_type} ) {
--             push @format,    $form"],
--             push @variables, $variab"],
--             next A"],
--         }
--         die "Unknown arg_type $arg_typ"],
--     } ## end for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 )
--     my $format_string =
--           q{"Problem in }
--         . $main::CLASS_LETTER . q{->}
--         . $function . '('
--         . ( join q{, }, @format )
--         . q{): %s"],
--     my @format_args = @variabl"],
--     push @format_args, qq{xs_g_error( $base "],
--     $output .= "    croak( $format_string,\"],
--     $output .= q{     } . (join q{, }, @format_args) . ");\"],
--     $output .= "  }\"],
--     $output .= q{  XPUSHs (sv_2mortal (newSViv (gp_result)));} . "\"],
--     $output .= "}\"],
--     return $outp"],
-- } ## end sub gp_generate

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

]=])

for ix = 1, #c_fn_signatures do
   local signature = c_fn_signatures[ix]
   local c_fn = signature[1]
   local unprefixed_name = string.gsub(c_fn, "^[_]?marpa_", "");
   class_letter = string.gsub(unprefixed_name, "_.*$", "");
   -- print( class_letter )
   local wrapper_name = "wrap_" .. unprefixed_name;
   io.write("static int ", wrapper_name, "(lua_State *L)\n");
   io.write("{\n");
   io.write("  ", class_type[class_letter], "* self;\n");
   local arg_ix = 2;
   while (arg_ix <= #signature) do
     io.write("  ", signature[arg_ix], " ", signature[arg_ix+1], ";\n");
     arg_ix = arg_ix + 2;
   end
   io.write("    int result;\n\n");

   -- These wrappers will not be external interfaces
   -- so eventually they will run unsafe.
   -- But for now we check arguments, and we'll leave
   -- the possibility for debugging
   local safe = true;
   if (safe) then
      io.write("  if (1) {\n")

      local check_for_table = [=[
    if (!lua_istable (L, 1))
    {
      luaL_error (L,
	"!!FUNCNAME!!() expected table as arg #1, got ",
        lua_typename (L, lua_type (L, 1)));
    }
]=]

      check_for_table =
           string.gsub(check_for_table, "!!FUNCNAME!!", wrapper_name);
      io.write(check_for_table);
      io.write("  }\n");
   end -- if (!unsafe)

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
