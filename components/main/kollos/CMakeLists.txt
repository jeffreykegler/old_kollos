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

ADD_CUSTOM_COMMAND (
  COMMENT "Writing grammar.lua"
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/grammar.lua
  COMMAND ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/luatangle
      ${CMAKE_CURRENT_SOURCE_DIR}/grammar.lua.md 
      ${CMAKE_CURRENT_BINARY_DIR}/grammar.lua
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/grammar.lua.md 
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/luatangle
  VERBATIM
  )

add_custom_target(
  grammar.lua ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/grammar.lua
  COMMENT "Writing grammar.lua"
  VERBATIM
)

ADD_CUSTOM_COMMAND (
  COMMENT "Writing a8lex.lua"
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/a8lex.lua
  COMMAND ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/luatangle
      ${CMAKE_CURRENT_SOURCE_DIR}/a8lex.lua.md 
      ${CMAKE_CURRENT_BINARY_DIR}/a8lex.lua
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/a8lex.lua.md 
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/luatangle
  VERBATIM
  )

add_custom_target(
  a8lex.lua ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/a8lex.lua
  COMMENT "Writing a8lex.lua"
  VERBATIM
)

ADD_CUSTOM_COMMAND (
  COMMENT "Writing recce.lua"
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/recce.lua
  COMMAND ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/luatangle
      ${CMAKE_CURRENT_SOURCE_DIR}/recce.lua.md 
      ${CMAKE_CURRENT_BINARY_DIR}/recce.lua
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/recce.lua.md 
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/luatangle
  VERBATIM
  )

add_custom_target(
  recce.lua ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/recce.lua
  COMMENT "Writing recce.lua"
  VERBATIM
)

file(COPY
    "config.lua"
    "development.lua"
    "inspect.lua"
    "location.lua"
    "lo_g.lua"
    "main.lua"
    "matrix.lua"
    "unindent.lua"
    "util.lua"
    "wrap.lua"
    DESTINATION
      ${CMAKE_CURRENT_BINARY_DIR}
    )

# vim: expandtab shiftwidth=4:
