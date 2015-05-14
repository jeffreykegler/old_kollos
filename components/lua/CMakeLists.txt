#
# Lua 5.1.x
#
CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(lua C)

if("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
   message(SEND_ERROR "In-source builds are not allowed.")
   endif("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")


# ------------------
# Module search path
# ------------------
ENABLE_TESTING()

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

macro(add_target_properties _target _name)
	set(_properties)
	foreach(_prop ${ARGN})
		set(_properties "${_properties} ${_prop}")
	endforeach(_prop)
	get_target_property(_old_properties ${_target} ${_name})
	if(NOT _old_properties)
		# in case it's NOTFOUND
		set(_old_properties)
	endif(NOT _old_properties)
	set_target_properties(${_target} PROPERTIES ${_name} "${_old_properties} ${_properties}")
endmacro(add_target_properties)

option(BUILD_STATIC "build static library" ON)

option(LUA_USE_DLOPEN "Enable dlopen support.")
option(LUA_USE_ISATTY "Enable isatty support.")
# option(LUA_USE_READLINE "Enable readline support.")
option(LUA_USE_POPEN "Enable lua_popen support.")
option(LUA_USE_ULONGJMP "Try using _longjmp/_setjmp (more efficient)")
option(LUA_USE_APICHECK "Enable API checks.")
option(LUA_USE_MKSTEMP "Use mkstemp.")
option(LUA_ANSI "Disable non-ansi features." OFF)

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
#
# Lua package info.
#
set(CPACK_PACKAGE_VERSION_MAJOR ${LUA_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${LUA_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${LUA_VERSION_PATCH})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYRIGHT")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README")
set(CPACK_PACKAGE_VENDOR "Lua.org, PUC-Rio.")
set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_SOURCE_IGNORE_FILES
"/\\\\.;/\\\\.git.*/;~$;build/;CMakeFiles/;CMakeCache;Testing/;cmake_install;CPack;Dart;Makefile$")
set(CPACK_SOURCE_PACKAGE_FILE_NAME
	"${CMAKE_PROJECT_NAME}-${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}.${LUA_VERSION_PATCH}")
# MUST be after CPACK_* variables.
include(CPack)

set(COMMON_CFLAGS)
set(COMMON_LDFLAGS " -lm ")

#
# Detect system type
#
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(LUA_USE_LINUX TRUE)
	set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_LINUX")
	# set(COMMON_LDFLAGS "${COMMON_LDFLAGS} -Wl,-E -ldl -lreadline -lhistory -lncurses")
	set(COMMON_LDFLAGS "${COMMON_LDFLAGS} -Wl,-E -ldl")
else(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	if(APPLE)
		set(LUA_USE_MACOSX TRUE)
		set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLUA_USE_LINUX")
		set(COMMON_LDFLAGS "${COMMON_LDFLAGS} -lreadline ")
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

#
# sub-folders
#
ADD_SUBDIRECTORY(src build)
# ADD_SUBDIRECTORY(test)

