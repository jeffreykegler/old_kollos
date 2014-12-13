CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(lua C)

FIND_PACKAGE(Lua51)
IF (LUA_INCLUDE_DIR)
  MESSAGE(STATUS "Lua include path: ${LUA_INCLUDE_DIR}")
ELSE ()
  message( FATAL_ERROR "Lua 5.1 not available.  Kollos cannot be built" )
ENDIF (LUA_INCLUDE_DIR)

include_directories("${LUA_INCLUDE_DIR}")
include_directories(${libmarpa_INCLUDE_DIRS})

add_executable(${PROJECT_NAME} lua.c)

target_link_libraries(${PROJECT_NAME} ${LUA_LIBRARIES})

# Expose location of Lua interpreter
set(${PROJECT_NAME}_INTERP ${PROJECT_BINARY_DIR}/lua
    CACHE INTERNAL "${PROJECT_NAME}: Include Directories" FORCE)

# vim: expandtab shiftwidth=4:
