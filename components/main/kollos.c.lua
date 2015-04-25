-- assumes that, when called, out_file to set to output file
local error_file

function c_safe_string (s)
    s = string.gsub(s, '"', '\\034')
    s = string.gsub(s, '\\', '\\092')
    return '"' .. s .. '"'
end

for k,v in ipairs(arg) do
   if not v:find("=")
   then return nil, "Bad options: ", arg end
   local id, val = v:match("^([^=]+)%=(.*)") -- no space around =
   if id == "out" then io.output(val)
   elseif id == "errors" then error_file = val
   else return nil, "Bad id in options: ", id end
end

-- initial piece
io.write[=[
/*
** Permission is hereby granted, free of charge, to any person obtaining
** a copy of this software and associated documentation files (the
** "Software"), to deal in the Software without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Software, and to
** permit persons to whom the Software is furnished to do so, subject to
** the following conditions:
**
** The above copyright notice and this permission notice shall be
** included in all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**
** [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
*/

#define LUA_LIB
#include "marpa.h"
#include "lua.h"
#include "lauxlib.h"

#include "compat-5.2.c"

#undef UNUSED
#if     __GNUC__ >  2 || (__GNUC__ == 2 && __GNUC_MINOR__ >  4)
#define UNUSED __attribute__((__unused__))
#else
#define UNUSED
#endif

#define EXPECTED_LIBMARPA_MAJOR 8
#define EXPECTED_LIBMARPA_MINOR 3
#define EXPECTED_LIBMARPA_MICRO 0

/* For debugging */
static void dump_stack (lua_State *L) {
      int i;
      int top = lua_gettop(L);
      for (i = 1; i <= top; i++) {  /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
    
          case LUA_TSTRING:  /* strings */
            printf("`%s'", lua_tostring(L, i));
            break;
    
          case LUA_TBOOLEAN:  /* booleans */
            printf(lua_toboolean(L, i) ? "true" : "false");
            break;
    
          case LUA_TNUMBER:  /* numbers */
            printf("%g", lua_tonumber(L, i));
            break;
    
          case LUA_TTABLE:  /* numbers */
            printf("table %s", lua_tostring(L, i));
            break;
    
          default:  /* other values */
            printf("%s", lua_typename(L, t));
            break;
    
        }
        printf("  ");  /* put a separator */
      }
      printf("\n");  /* end the listing */
}

static void dump_table(lua_State *L, int index)
{
    /* Original stack: [ ... ] */
    lua_pushvalue(L, index);
    lua_pushnil(L);
    /* [ ..., table, nil ] */
    while (lua_next(L, -2))
    {
        const char *key;
        const char *value;
        /* [ ..., table, key, value ] */
        lua_pushvalue(L, -2);
        /* [ ..., table, key, value, key ] */
        key = lua_tostring(L, -1);
        value = lua_tostring(L, -2);
        printf("%s => %s\n", key, value);
        lua_pop(L, 2);
        /* [ ..., table, key ] */
    }
    /* [ ..., table ] */
    lua_pop(L, 1);
    /* Back to original stack: [ ... ] */
}

]=]

-- error codes

io.write[=[
struct s_libmarpa_error_code {
   lua_Integer code;
   const char* mnemonic;
   const char* description;
};

]=]

do
    local f = assert(io.open(error_file, "r"))
    local code_lines = {}
    local code_mnemonics = {}
    local max_code = 0
    while true do
        local line = f:read()
        if line == nil then break end
        local i, j = string.find(line, "#")
        if (i == nil) then stripped = line
        else stripped = string.sub(line, 0, i-1)
        end
        if string.find(stripped, "%S") then
            local raw_code
            local raw_mnemonic
            local description
            _, _, raw_code, raw_mnemonic, description = string.find(stripped, "^(%d+)%sMARPA_ERR_(%S+)%s(.*)$")
            local code = tonumber(raw_code)
            if description == nil then return nil, "Bad line in error code file ", line end
            if code > max_code then max_code = code end
            local mnemonic = 'LUIF_ERR_' .. raw_mnemonic
            code_mnemonics[code] = mnemonic
            code_lines[code] = string.format( '   { %d, %s, %s },',
                code,
                c_safe_string(mnemonic),
                c_safe_string(description)
                )
        end
    end

    io.write('#define LIBMARPA_MIN_ERROR_CODE 0\n')
    io.write('#define LIBMARPA_MAX_ERROR_CODE ' .. max_code .. '\n\n')

    for i = 0, max_code do
        local mnemonic = code_mnemonics[i]
        if mnemonic then
            io.write(
                   string.format('#define %s %d\n', mnemonic, i)
           )
       end
    end
    io.write('\n')
    io.write('struct s_libmarpa_error_code libmarpa_error_codes[LIBMARPA_MAX_ERROR_CODE-LIBMARPA_MIN_ERROR_CODE+1] = {\n')
    for i = 0, max_code do
        local code_line = code_lines[i]
        if code_line then
           io.write(code_line .. '\n')
        else
           io.write(
               string.format(
                   '    { %d, "LUIF_ERROR_RESERVED", "Unknown Libmarpa error %d" },\n',
                   i, i
               )
           )
        end
    end
    io.write('};\n\n');
    f:close()
end

-- for Kollos's own (that is, non-Libmarpa) error codes
do
    local code_lines = {}
    local code_mnemonics = {}
    local min_code = 200
    local max_code = 200

    -- Should add some checks on the errors, checking for
    -- 1.) duplicate mnenomics
    -- 2.) duplicate error codes

    function luif_error_add (code, mnemonic, description)
        code_mnemonics[code] = mnemonic
        code_lines[code] = string.format( '   { %d, %s, %s },',
            code,
            c_safe_string(mnemonic),
            c_safe_string(description)
            )
        if code > max_code then max_code = code end
    end

    -- LUIF_ERR_RESERVED_200 is a place-holder , not expected to be actually used
    luif_error_add( 200, "LUIF_ERR_RESERVED_200", "Unexpected Kollos error: 200")
    luif_error_add( 201, "LUIF_ERR_LUA_VERSION", "Bad Lua version")
    luif_error_add( 202, "LUIF_ERR_LIBMARPA_HEADER_VERSION_MISMATCH", "Libmarpa header does not match expected version")
    luif_error_add( 203, "LUIF_ERR_LIBMARPA_LIBRARY_VERSION_MISMATCH", "Libmarpa library does not match expected version")

    io.write('#define KOLLOS_MIN_ERROR_CODE ' .. min_code .. '\n')
    io.write('#define KOLLOS_MAX_ERROR_CODE ' .. max_code .. '\n\n')
    for i = min_code, max_code
    do
        local mnemonic = code_mnemonics[i]
        if mnemonic then
            io.write(
                   string.format('#define %s %d\n', mnemonic, i)
           )
       end
    end

    io.write('\n')
    io.write('struct s_libmarpa_error_code kollos_error_codes[(KOLLOS_MAX_ERROR_CODE-KOLLOS_MIN_ERROR_CODE)+1] = {\n')
    for i = min_code, max_code do
        local code_line = code_lines[i]
        if code_line then
           io.write(code_line .. '\n')
        else
           io.write(
               string.format(
                   '    { %d, "LUIF_ERROR_RESERVED", "Unknown Kollos error %d" },\n',
                   i, i
               )
           )
        end
    end
    io.write('};\n\n');

end

-- error objects
--
-- There are written in C, but not because of efficiency --
-- efficiency is not needed, and in any case, when the overhead
-- from the use of the debug calls is considered, is not really
-- gained.
--
-- The reason for the use of C is that the error routines
-- must be available for use inside both C and Lua, and must
-- also be available as early as possible during set up.
-- It's possible to run Lua code both inside C and early in
-- the set up, but the added unclarity, complexity from issues
-- of error reporting for the Lua code, etc., etc. mean that
-- it actually is easier to write them in C than in Lua.

io.write[=[

static inline const char* error_description_by_code(lua_Integer error_code)
{
   if (error_code >= LIBMARPA_MIN_ERROR_CODE && error_code <= LIBMARPA_MAX_ERROR_CODE) {
       return libmarpa_error_codes[error_code-LIBMARPA_MIN_ERROR_CODE].description;
   }
   if (error_code >= KOLLOS_MIN_ERROR_CODE && error_code <= KOLLOS_MAX_ERROR_CODE) {
       return kollos_error_codes[error_code-KOLLOS_MIN_ERROR_CODE].description;
   }
   return (const char *)0;
}

static inline int l_error_description_by_code(lua_State* L)
{
   const lua_Integer error_code = luaL_checkinteger(L, 1);
   const char* description = error_description_by_code(error_code);
   if (description)
   {
       lua_pushfstring(L, "Unknown error code (%d)", error_code);
   } else {
       lua_pushstring(L, description);
   }
   return 1;
}
 
/* userdata metatable keys
   The contents of these locations are never examined.
   These location are used as a key in the Lua registry.
   This guarantees that the key will be unique
   within the Lua state.
*/
static char kollos_error_mt_key;
static char kollos_g_ud_mt_key;
static char kollos_r_ud_mt_key;

/* Leaves the stack as before,
   except with the error object on top */
static inline void kollos_error(lua_State* L,
    lua_Number code, const char* details)
{
   lua_newtable(L);
   /* [ ..., error_object ] */
   lua_rawgetp(L, LUA_REGISTRYINDEX, &kollos_error_mt_key);
   /* [ ..., error_object, error_metatable ] */
   lua_setmetatable(L, -2);
   /* [ ..., error_object ] */
   lua_pushnumber(L, code);
   lua_setfield(L, -2, "code" );
   /* [ ..., error_object ] */
   lua_pushstring(L, details);
   lua_setfield(L, -2, "details" );
   /* [ ..., error_object ] */
}

/* Replace an error object, on top of the stack,
   with its string equivalent
 */
static inline void error_tostring(lua_State* L)
{
  const int error_object_ix = lua_gettop (L);
  /* [ ..., error_object ] */
  lua_getfield (L, -1, "string");

  /* [ ..., error_object, string ] */

  if (lua_isnil (L, -1))
    {
      /* [ ..., error_object, nil ] */
      lua_pop (L, 1);
      lua_getfield (L, error_object_ix, "where");
      if (lua_isnil (L, -1))
	{
	  lua_pop (L, 1);
	  lua_pushstring (L, "???: ");
	}
      /* [ ..., error_object, where ] */
      lua_getfield (L, error_object_ix, "code");
      if (lua_isnil (L, -1))
	{
	  lua_pop (L, 1);
	  lua_pushstring (L, "");
	}
      else
	{
	  lua_Integer error_code = lua_tointeger (L, -1);
	  const char *description = error_description_by_code (error_code);
	  if (description)
	    {
	      lua_pushstring (L, description);
	    }
	  else
	    {
	      lua_pushfstring (L, "Unknown error code (%d)",
			       (int) error_code);
	    }
	}
      /* [ ..., error_object, where, code_description ] */
      lua_getfield (L, error_object_ix, "details");
      if (lua_isnil (L, -1))
	{
	  lua_pop (L, 1);
	  lua_pushstring (L, "");
	}
      /* [ ..., error_object, where, code_description, details ] */
      lua_pushfstring (L, "%s %s\n%s",
		       lua_tostring (L, -3),
		       lua_tostring (L, -2), lua_tostring (L, -1));
      /* [ ..., error_object, where, code_description, details, result ] */
    }

  /* [ ..., error_object, ..., result ] */
  lua_replace (L, error_object_ix);
  lua_settop (L, error_object_ix);
  /* [ ..., result ] */
}
  
static inline void kollos_throw(lua_State* L,
    lua_Number code, const char* details)
{
   kollos_error(L, code, details);
   error_tostring(L);
   lua_error(L);
}

static int l_error_tostring(lua_State* L)
{
   /* [ error_object ] */
   luaL_checktype(L, 1, LUA_TTABLE);
   error_tostring(L);
   /* [ error_string ] */
  return 1;
}
  
]=]

-- functions

io.write[=[

static void luif_err_throw(lua_State *L, int error_code) {

#if 0
    const char *where;
    luaL_where(L, 1);
    where = lua_tostring(L, -1);
#endif

    if (error_code < LIBMARPA_MIN_ERROR_CODE || error_code > LIBMARPA_MAX_ERROR_CODE) {
        luaL_error(L, "Libmarpa returned invalid error code %d", error_code);
    }
    luaL_error(L, "%s", libmarpa_error_codes[error_code].description );
}

static void luif_err_throw2(lua_State *L, int error_code, const char *msg) {

#if 0
    const char *where;
    luaL_where(L, 1);
    where = lua_tostring(L, -1);
#endif

    if (error_code < 0 || error_code > LIBMARPA_MAX_ERROR_CODE) {
        luaL_error(L, "%s\n    Libmarpa returned invalid error code %d", msg, error_code);
    }
    luaL_error(L, "%s\n    %s", msg, libmarpa_error_codes[error_code].description);
}

static void check_libmarpa_table(
    lua_State* L, const char *function_name, int stack_ix, const char *expected_type)
{
  const char *actual_type;
  /* stack is [ ... ] */
  if (!lua_istable (L, stack_ix))
    {
      const char *typename = lua_typename (L, lua_type (L, stack_ix));
      luaL_error (L, "%s arg #1 type is %s, expected table",
		  function_name, typename);
    }
  lua_getfield (L, stack_ix, "_type");
  /* stack is [ ..., field ] */
  if (!lua_isstring (L, -1))
    {
      const char *typename = lua_typename (L, lua_type (L, -1));
      luaL_error (L, "%s arg #1 field '_type' is %s, expected string",
		  function_name, typename);
    }
  actual_type = lua_tostring (L, -1);
  if (strcmp (actual_type, expected_type))
    {
      luaL_error (L, "%s arg #1 table is %s, expected %s",
		  function_name, actual_type, expected_type);
    }
  /* stack is [ ..., field ] */
  lua_pop (L, 1);
  /* stack is [ ... ] */
}

]=]

-- Here are the meta-programmed wrappers --
-- this is Lua code which writes the C code based on
-- a "signature" for the wrapper
--
-- This meta-programming does not attempt to work for
-- all of the wrappers.  It works only when
--   1.) The number of arguments is fixed.
--   2.) Their type is from a fixed list.
--   3.) Converting the return value to int is a good thing to do.
--   4.) Non-negatvie return values indicate success
--   5.) Return values less than -1 indicate failure
--   6.) Return values less than -1 set the error code
--   7.) Return value of -1 is "soft" and returning nil is
--       the right thing to do

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

local libmarpa_class_type = {
  g = "Marpa_Grammar",
  r = "Marpa_Recognizer",
  b = "Marpa_Bocage",
  o = "Marpa_Order",
  t = "Marpa_Tree",
  v = "Marpa_Value",
};

local libmarpa_class_name = {
  g = "grammar",
  r = "recce",
  b = "bocage",
  o = "order",
  t = "tree",
  v = "value",
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
  {"marpa_r_alternative", "Marpa_Symbol_ID", "token", "int", "value", "int", "length"}, -- See note
  {"marpa_r_current_earleme"},
  {"marpa_r_earleme_complete"}, -- See note below
  {"marpa_r_earleme", "Marpa_Earley_Set_ID", "ordinal"},
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
  {"marpa_r_start_input"},
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

-- Here are notes
-- on those methods for which the wrapper requirements are "bent"
-- a little bit.
--
-- marpa_r_alternative() -- generates events
--  Returns an error code.  Since these are always non-negative, from
--  the wrapper's point of view, marpa_r_alternative() always succeeds.
--
-- marpa_r_earleme_complete() -- generates events

local check_for_table_template = [=[
!!INDENT!!check_libmarpa_table(L,
!!INDENT!!  "!!FUNCNAME!!",
!!INDENT!!  self_stack_ix,
!!INDENT!!  "!!CLASS_NAME!!"
!!INDENT!!);
]=]

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
   io.write("  ", libmarpa_class_type[class_letter], " self;\n");
   io.write("  const int self_stack_ix = 1;\n");
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
      check_for_table =
        string.gsub(check_for_table, "!!CLASS_NAME!!", libmarpa_class_name[class_letter])
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
   local cast_to_ptr_to_class_type = "(" ..  libmarpa_class_type[class_letter] .. "*)"
   io.write("  self = *", cast_to_ptr_to_class_type, "lua_touserdata (L, -1);\n")
   io.write("  lua_pop(L, 1);\n")
   -- stack is [ self ]

   io.write('  lua_getfield (L, -1, "_g_ud");\n')
   -- stack is [ self, grammar_ud ]
   io.write("  grammar = *(Marpa_Grammar*)lua_touserdata (L, -1);\n")
   io.write("  lua_pop(L, 1);\n")
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

   -- Now write the code that adds the functions to the kollos object

end

-- grammar wrappers which need to be hand written

io.write[=[

static int wrap_grammar_new(lua_State *L)
{
  /* [ grammar_table ] */
  const int grammar_stack_ix = 1;
  printf ("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);

  /* expecting a table */
  if (1)
    {
      check_libmarpa_table (L, "wrap_grammar_NEW()", grammar_stack_ix,
			    "grammar");
    }

  /* I have forked Libmarpa into Kollos, which makes version checking
   * pointless.  But we may someday use the LuaJIT,
   * and version checking will be needed there.
   */

  {
    const char *const header_mismatch =
      "Header version does not match expected version";
    /* Make sure the header is from the version we want */
    if (MARPA_MAJOR_VERSION != EXPECTED_LIBMARPA_MAJOR)
      luif_err_throw2 (L, LUIF_ERR_MAJOR_VERSION_MISMATCH, header_mismatch);
    if (MARPA_MINOR_VERSION != EXPECTED_LIBMARPA_MINOR)
      luif_err_throw2 (L, LUIF_ERR_MINOR_VERSION_MISMATCH, header_mismatch);
    if (MARPA_MICRO_VERSION != EXPECTED_LIBMARPA_MICRO)
      luif_err_throw2 (L, LUIF_ERR_MICRO_VERSION_MISMATCH, header_mismatch);
  }

  {
    /* Now make sure the library is from the version we want */
    const char *const library_mismatch =
      "Library version does not match expected version";
    int version[3];
    const Marpa_Error_Code error_code = marpa_version (version);
    if (error_code != MARPA_ERR_NONE)
      luif_err_throw2 (L, error_code, "marpa_version() failed");
    if (version[0] != EXPECTED_LIBMARPA_MAJOR)
      luif_err_throw2 (L, LUIF_ERR_MAJOR_VERSION_MISMATCH, library_mismatch);
    if (version[1] != EXPECTED_LIBMARPA_MINOR)
      luif_err_throw2 (L, LUIF_ERR_MINOR_VERSION_MISMATCH, library_mismatch);
    if (version[2] != EXPECTED_LIBMARPA_MICRO)
      luif_err_throw2 (L, LUIF_ERR_MICRO_VERSION_MISMATCH, library_mismatch);
  }

  /* For testing the error mechanism */
  /* luif_err_throw(L, LUIF_ERR_I_AM_NOT_OK); */

  /* [ grammar_table ] */
  {
    Marpa_Config marpa_config;
    Marpa_Grammar *p_g;
    int result;
    /* [ grammar_table ] */
    p_g = (Marpa_Grammar *) lua_newuserdata (L, sizeof (Marpa_Grammar));
    /* [ grammar_table, userdata ] */
    lua_rawgetp (L, LUA_REGISTRYINDEX, &kollos_g_ud_mt_key);
    lua_setmetatable (L, -2);
    /* [ grammar_table, userdata ] */

    /* dup top of stack */
    lua_pushvalue (L, -1);
    /* [ grammar_table, userdata, userdata ] */
    lua_setfield (L, grammar_stack_ix, "_ud");
    /* [ grammar_table, userdata ] */
    lua_setfield (L, grammar_stack_ix, "_g_ud");
    /* [ grammar_table ] */

    marpa_c_init (&marpa_config);
    *p_g = marpa_g_new (&marpa_config);
    if (!*p_g)
      {
	Marpa_Error_Code marpa_error = marpa_c_error (&marpa_config, NULL);
	kollos_throw (L, marpa_error, "marpa_g_new()");
      }
    result = marpa_g_force_valued (*p_g);
    if (result < 0)
      {
	Marpa_Error_Code marpa_error = marpa_g_error (*p_g, NULL);
	kollos_throw (L, marpa_error, "marpa_g_force_valued()");
      }
  }
  printf ("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
  /* [ grammar_table ] */
  return 1;
}

static int wrap_grammar_rule_new(lua_State *L)
{
    Marpa_Grammar *p_g;
    Marpa_Rule_ID result;
    Marpa_Symbol_ID lhs;
    Marpa_Symbol_ID rhs[2];
    int rhs_length;
    /* [ grammar_object, lhs, rhs ... ] */
    const int grammar_stack_ix = 1;

    /* This will not be an external interface,
     * so eventually we will run unsafe.
     * This checking code is for debugging.
     */
    if (1)
      {
        check_libmarpa_table (L, "wrap_grammar_rule_new()", grammar_stack_ix,
                              "grammar");
      }

    lhs = (Marpa_Symbol_ID)lua_tointeger(L, 2);
    /* Unsafe, no arg count checking */
    rhs_length = lua_gettop(L) - 2;
    {
      int rhs_ix;
      for (rhs_ix = 0; rhs_ix < rhs_length; rhs_ix++)
        {
          rhs[rhs_ix] = (Marpa_Symbol_ID) lua_tointeger (L, rhs_ix + 3);
        }
    }
    lua_pop(L, lua_gettop(L)-1);
    /* [ grammar_object ] */

    lua_getfield (L, -1, "_ud");
    /* [ grammar_object, grammar_ud ] */
    p_g = (Marpa_Grammar *) lua_touserdata (L, -1);

    result = (Marpa_Rule_ID)marpa_g_rule_new(*p_g, lhs, rhs, rhs_length);
    if (result <= -1) {
        Marpa_Error_Code marpa_error = marpa_g_error(*p_g, NULL);
        kollos_throw( L, marpa_error, "marpa_g_rule_new()" );
    }
    lua_pushinteger(L, (lua_Integer)result);
    return 1;
}

]=]

-- recognizer wrappers which need to be hand-written

io.write[=[

static int wrap_recce_new(lua_State *L)
{
  const int recce_stack_ix = 1;
  const int grammar_stack_ix = 2;
  printf ("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
  /* [ recce_table, grammar_table ] */
  if (1)
    {
      check_libmarpa_table (L, "wrap_recce_new()", recce_stack_ix, "recce");
      check_libmarpa_table (L, "wrap_recce_new()", grammar_stack_ix,
			    "grammar");
    }

  /* [ recce_table, grammar_table ] */
  {
    Marpa_Recognizer *recce_ud;
    Marpa_Grammar *grammar_ud;

    /* [ recce_table, grammar_table ] */
    recce_ud =
      (Marpa_Recognizer *) lua_newuserdata (L, sizeof (Marpa_Recognizer));
    /* [ recce_table, , grammar_table, recce_ud ] */
    lua_rawgetp (L, LUA_REGISTRYINDEX, &kollos_r_ud_mt_key);
    /* [ recce_table, grammar_table, recce_ud, recce_ud_mt ] */
    lua_setmetatable (L, -2);
    /* [ recce_table, grammar_table, recce_ud ] */

    lua_setfield (L, recce_stack_ix, "_ud");
    /* [ recce_table, grammar_table ] */
    lua_getfield (L, grammar_stack_ix, "_g_ud");
    /* [ recce_table, grammar_table, g_ud ] */
    grammar_ud = (Marpa_Grammar *) lua_touserdata (L, -1);
    lua_setfield (L, recce_stack_ix, "_g_ud");
    /* [ recce_table, grammar_table ] */

    *recce_ud = marpa_r_new (*grammar_ud);
    if (!*recce_ud)
      {
	Marpa_Error_Code marpa_error = marpa_g_error (*grammar_ud, NULL);
	kollos_throw (L, marpa_error, "marpa_r_new()");
      }
  }
  printf ("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
  /* [ recce_table, grammar_table ] */
  lua_pop(L, 1);
  /* [ recce_table ] */
  return 1;
}

]=]

io.write[=[

/*
 * Userdata metatable methods
 */

static int l_grammar_ud_mt_gc(lua_State *L) {
    Marpa_Grammar *p_g;
        printf("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
    p_g = (Marpa_Grammar *) lua_touserdata (L, 1);
    if (*p_g) marpa_g_unref(*p_g);
   return 0;
}

static int l_recce_ud_mt_gc(lua_State *L) {
    Marpa_Recognizer *p_recce;
        printf("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
    p_recce = (Marpa_Recognizer *) lua_touserdata (L, 1);
    if (*p_recce) marpa_r_unref(*p_recce);
   return 0;
}

LUALIB_API int luaopen_kollos_c(lua_State *L);
LUALIB_API int luaopen_kollos_c(lua_State *L)
{
  /* Create the main kollos object */
  lua_newtable(L);

  /* Set up Kollos error handling metatable */
  lua_newtable(L);
  /* [ kollos, error_mt ] */
  lua_pushcclosure(L, l_error_tostring, 0);
  /* [ kollos, error_mt, tostring_fn ] */
  lua_setfield(L, -2, "__tostring");
  /* [ kollos, error_mt ] */
  lua_rawsetp(L, LUA_REGISTRYINDEX, &kollos_error_mt_key);
  /* [ kollos ] */

  /* Set up Kollos grammar userdata metatable */
  lua_newtable(L);
  /* [ kollos, mt_ud_g ] */
  /* dup top of stack */
  lua_pushcfunction(L, l_grammar_ud_mt_gc);
  /* [ kollos, mt_g_ud, gc_function ] */
  lua_setfield(L, -2, "__gc");
  /* [ kollos, mt_g_ud ] */
  lua_rawsetp(L, LUA_REGISTRYINDEX, &kollos_g_ud_mt_key);
  /* [ kollos ] */

  /* Set up Kollos recce userdata metatable */
  lua_newtable(L);
  /* [ kollos, mt_ud_r ] */
  /* dup top of stack */
  lua_pushcfunction(L, l_recce_ud_mt_gc);
  /* [ kollos, mt_r_ud, gc_function ] */
  lua_setfield(L, -2, "__gc");
  /* [ kollos, mt_r_ud ] */
  lua_rawsetp(L, LUA_REGISTRYINDEX, &kollos_r_ud_mt_key);
  /* [ kollos ] */

  lua_pushcfunction(L, wrap_grammar_new);
  /* [ kollos, grammar_new_function ] */
  lua_setfield(L, -2, "grammar_new");
  /* [ kollos ] */

  lua_pushcfunction(L, wrap_grammar_rule_new);
  lua_setfield(L, -2, "grammar_rule_new");

  lua_pushcfunction(L, wrap_recce_new);
  /* [ kollos, recce_new_function ] */
  lua_setfield(L, -2, "recce_new");
  /* [ kollos ] */

]=]

-- This code goes through the signatures table again,
-- to put the wrappers into kollos object fields

for ix = 1, #c_fn_signatures do
   local signature = c_fn_signatures[ix]
   local function_name = signature[1]
   local unprefixed_name = string.gsub(function_name, "^[_]?marpa_", "");
   local class_letter = string.gsub(unprefixed_name, "_.*$", "");
   local wrapper_name = "wrap_" .. unprefixed_name;
   io.write("  lua_pushcfunction(L, " .. wrapper_name .. ");\n")
   local classless_name = string.gsub(function_name, "^[_]?marpa_[^_]*_", "")
   local quoted_field_name = '"' .. libmarpa_class_name[class_letter] .. '_' .. classless_name .. '"'
   io.write("  lua_setfield(L, -2, " .. quoted_field_name .. ");\n")
end

io.write[=[
  /* [ kollos ] */
  /* For debugging */
  if (1) dump_table(L, -1);

  /* For testing the error mechanism */
  if (0) kollos_throw( L, LUIF_ERR_I_AM_NOT_OK, "test" );

  /* Fail if not 5.1 ? */

  /* [ kollos ] */
  return 1;
}

/* vim: expandtab shiftwidth=4:
 */
]=]
