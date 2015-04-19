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

#define EXPECTED_LIBMARPA_MAJOR 7
#define EXPECTED_LIBMARPA_MINOR 5
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
 
/* The contents of this location are never examined.
   The location is used as a key in the Lua registry
   for the kollos error object's metatable.
   This guarantees that the key will be unique
   within the Lua state.
*/
static char kollos_error_mt_key;

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

static int l_grammar_new(lua_State *L)
{
        printf("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
    /* expecting a table */
    luaL_checktype(L, 1, LUA_TTABLE);

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

  /* [ kollos ] */
  {
    Marpa_Config marpa_config;
    Marpa_Grammar *p_g;
    int result;
    p_g = (Marpa_Grammar *) lua_newuserdata (L, sizeof (Marpa_Grammar));
    /* [ kollos, userdata ] */
    lua_getfield (L, -2, "_mt_g_ud");
    /* [ kollos, userdata, mt_g_ud ] */
    lua_setmetatable (L, -2);
    /* [ kollos, userdata ] */
    lua_pop (L, 1);
    /* [ kollos ] */
    marpa_c_init(&marpa_config);
    *p_g = marpa_g_new(&marpa_config);
    if (!*p_g) {
        Marpa_Error_Code marpa_error = marpa_c_error(&marpa_config, NULL);
        kollos_throw( L, marpa_error, "marpa_g_new()" );
    }
    result = marpa_g_force_valued(*p_g);
    if (result < 0) {
        Marpa_Error_Code marpa_error = marpa_g_error(*p_g, NULL);
        kollos_throw( L, marpa_error, "marpa_g_force_valued()" );
    }
  }
        printf("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
  return 1;
}

static int l_grammar_ud_mt_gc(lua_State *L) {
    Marpa_Grammar *p_g;
        printf("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
    p_g = (Marpa_Grammar *) lua_touserdata (L, 1);
    if (*p_g) marpa_g_unref(*p_g);
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
  /* [ kollos, mt_g ] */
  /* dup top of stack */
  lua_pushvalue(L, -1);
  /* [ kollos, mt_g_ud, mt_g_ud ] */
  lua_setfield(L, -3, "_mt_g_ud");
  /* [ kollos, mt_g_ud ] */
  lua_pushcfunction(L, l_grammar_ud_mt_gc);
  /* [ kollos, mt_g_ud, gc_function ] */
  lua_setfield(L, -2, "__gc");
  /* [ kollos, mt_g_ud ] */
        printf("%s %s %d\n", __PRETTY_FUNCTION__, __FILE__, __LINE__);
  lua_pop(L, 1);
  /* [ kollos ] */
  lua_pushcfunction(L, l_grammar_new);
  /* [ kollos, grammar_new_function ] */
  lua_setfield(L, -2, "grammar");
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
