find_program(LuaInterp lua)

IF(${LuaInterp} STREQUAL "LuaInterp-NOTFOUND") 
  MESSAGE(FATAL_ERROR " Lua interpreter not found. Can't make version detection. Compilation might not work ")
ENDIF()

execute_process(COMMAND ${LuaInterp} -v ERROR_VARIABLE LUA_OUTPUT)

# capture just the first 2 components of the version number
STRING(REGEX MATCH "Lua ([0-9]+.[0-9]+)" DUMMY ${LUA_OUTPUT})
SET(LUA_VERSION ${CMAKE_MATCH_1})

IF (${LUA_VERSION} VERSION_EQUAL "5.1")
  MESSAGE(STATUS "Found Lua interpreter, version = ${LUA_VERSION}")
ELSE()
  MESSAGE(FATAL_ERROR "Lua reports unsupported version ${LUA_VERSION}")
ENDIF()

SET(LUA ${LuaInterp} CACHE STRING "The Lua interpreter")
