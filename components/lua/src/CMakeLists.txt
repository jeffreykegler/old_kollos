
# Lua core source files.
set(LUA_CORE_SRC
	lapi.c
	lauxlib.c
	lbaselib.c
	lcode.c
	ldblib.c
	ldebug.c
	ldo.c
	ldump.c
	lfunc.c
	lgc.c
	linit.c
	liolib.c
	llex.c
	lmathlib.c
	lmem.c
	loadlib.c
	lobject.c
	lopcodes.c
	loslib.c
	lparser.c
	lstate.c
	lstring.c
	lstrlib.c
	ltable.c
	ltablib.c
	ltm.c
	lundump.c
	lvm.c
	lzio.c
)
set(LUA_LIB_HEADERS
	lua.h
	lualib.h
	lauxlib.h
	luaconf.h
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
				${CMAKE_CURRENT_BINARY_DIR})

#
# Lua library.
#

# static build only
add_library(lua STATIC ${LUA_CORE_SRC})
add_target_properties(lua COMPILE_FLAGS "${COMMON_CFLAGS}")
add_target_properties(lua LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}")
set_target_properties(lua
                      PROPERTIES POSITION_INDEPENDENT_CODE ON)

set(LUA_STATIC_LIB lua)
set(LUA_LIBS lua)

set_target_properties(${LUA_LIBS} PROPERTIES
	VERSION ${LUA_VERSION}
	SOVERSION ${LUA_SOVERSION}
	CLEAN_DIRECT_OUTPUT 1
)

#
# Lua compiler
#
add_executable(luac luac.c print.c)
add_target_properties(luac COMPILE_FLAGS "${COMMON_CFLAGS}")
add_target_properties(luac LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}")
target_link_libraries(luac ${LUA_STATIC_LIB})

#
# Lua stand-alone interpreter
#
add_executable(lua.bin lua.c)
add_target_properties(lua.bin COMPILE_FLAGS "${COMMON_CFLAGS}")
add_target_properties(lua.bin LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}")
target_link_libraries(lua.bin lua)
# rename lub.bin to lua
set_target_properties(lua.bin PROPERTIES OUTPUT_NAME lua)

