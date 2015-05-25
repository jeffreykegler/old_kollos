CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

PROJECT(kollos C)

if("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
   message(SEND_ERROR "In-source builds are not allowed.")
   endif("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")

# ------------------
# Module search path
# ------------------
SET (CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/modules")
ENABLE_TESTING()

set(LUA_Sources "kollos.lua")
source_group("lua" FILES ${LUA_Sources})

set(LUA_Outputs "")
foreach(LuaFile ${LUA_Sources})
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${LuaFile}
    COMMAND ${CMAKE_COMMAND}
    ARGS -E copy_if_different
      ${CMAKE_CURRENT_SOURCE_DIR}/${LuaFile}
      ${CMAKE_CURRENT_BINARY_DIR}/${LuaFile}
  )
  list(APPEND LUA_Outputs ${CMAKE_CURRENT_BINARY_DIR}/${LuaFile})
endforeach()

add_custom_target(
  copy_kollos_lua ALL
  DEPENDS ${LUA_Outputs}
  COMMENT "Copying LUA files"
  VERBATIM
)

add_subdirectory(kollos) # kollos-wide tests

# vim: expandtab shiftwidth=4:
