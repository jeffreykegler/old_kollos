#
# Lua version
#
set(LUA_VERSION_MAJOR 5)
set(LUA_VERSION_MINOR 1)
set(LUA_VERSION_PATCH 5)
set(LUA_VERSION
				"${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}.${LUA_VERSION_PATCH}")
set(LUA_SOVERSION
				"${LUA_VERSION_MAJOR}")
set(COMMON_CFLAGS)
set(EXTRA_LIBS "-lm")
#
# Detect system type
#
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(LUA_USE_LINUX TRUE)

	# Do not set LUA_USE_LINUX because I do not bother with readline
	# set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_LINUX")
	set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_POSIX -DLUA_USE_DLOPEN")

	# We link static, so no '-E' flag
	# We also don't use readline
	# set(COMMON_LDFLAGS "${COMMON_LDFLAGS} -Wl,-E -ldl -lreadline -lhistory -lncurses")

	set(EXTRA_LIBS ${EXTRA_LIBS} "-ldl")

else(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	if(APPLE)
		set(LUA_USE_MACOSX TRUE)
		# set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_LINUX")
		set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_POSIX -DLUA_USE_DLOPEN")
		# use this on Mac OS X 10.3-
		#set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_MACOSX")
	elseif(WIN32)
		set(LUA_WIN TRUE)
		set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_BUILD_AS_DLL")
	elseif(UNIX)
		set(LUA_USE_POSIX TRUE)
		set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_POSIX")
	else(APPLE)
		set(LUA_ANSI TRUE)
		set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_ANSI")
	endif(APPLE)
endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

#
# standard flags to use for each build type.
#
if(CMAKE_COMPILER_IS_GNUCC)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pipe -Wall -Wextra -Wshadow -W -pedantic -std=gnu99 -fgnu89-inline")
	set(CMAKE_C_FLAGS_RELEASE        "${CMAKE_C_FLAGS_RELEASE}     -O2")
	set(CMAKE_C_FLAGS_DEBUG          "${CMAKE_C_FLAGS_DEBUG}       -O0 -g")
	set(CMAKE_C_FLAGS_PROFILE        "${CMAKE_C_FLAGS_PROFILE}     -O1 -g")
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_WITHDEBINFO} -O2 -g")
endif(CMAKE_COMPILER_IS_GNUCC)

  message(WARNING "COMMON_CFLAGS " ${COMMON_CFLAGS})
  message(WARNING "COMMON_LDFLAGS " ${COMMON_LDFLAGS})

# Lua core source files.
set(LUA_CORE_SRC
	bit.c # extended with LuaJIT's bit library
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
set_target_properties(lua PROPERTIES
  COMPILE_FLAGS "${COMMON_CFLAGS}"
  LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}"
  POSITION_INDEPENDENT_CODE ON
  VERSION ${LUA_VERSION}
  SOVERSION ${LUA_SOVERSION}
  CLEAN_DIRECT_OUTPUT 1
)

set(LUA_STATIC_LIB lua)

#
# Lua compiler
#
add_executable(luac luac.c print.c)
set_target_properties(luac PROPERTIES
  COMPILE_FLAGS "${COMMON_CFLAGS}"
  LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}"
)
target_link_libraries(luac ${LUA_STATIC_LIB} ${EXTRA_LIBS})

#
# Lua stand-alone interpreter
#
add_executable(lua.bin lua.c)
set_target_properties(lua.bin PROPERTIES
  COMPILE_FLAGS "${COMMON_CFLAGS}"
  LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}"
  # rename lub.bin to lua
  OUTPUT_NAME lua
)
target_link_libraries(lua.bin lua ${EXTRA_LIBS})

# Expose location of Lua interpreter
set(${PROJECT_NAME}_INTERP ${PROJECT_BINARY_DIR}/src/lua
    CACHE INTERNAL "${PROJECT_NAME}: Include Directories" FORCE)

