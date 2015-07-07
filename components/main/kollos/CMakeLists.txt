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
  COMMAND cp
      ${CMAKE_CURRENT_SOURCE_DIR}/grammar.lua.md 
      ${CMAKE_CURRENT_BINARY_DIR}/grammar.lua
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/grammar.lua.md 
  VERBATIM
  )

add_custom_target(
  grammar.lua ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/grammar.lua
  COMMENT "Writing grammar.lua"
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
