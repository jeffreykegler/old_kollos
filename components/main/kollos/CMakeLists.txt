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

file(COPY
    "config.lua"
    "development.lua"
    "inspect.lua"
    "grammar.lua"
    "location.lua"
    "lo_g.lua"
    "main.lua"
    "unindent.lua"
    "util.lua"
    "wrap.lua"
    DESTINATION
      ${CMAKE_CURRENT_BINARY_DIR}
    )

# vim: expandtab shiftwidth=4:
