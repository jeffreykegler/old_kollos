CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(test_luif C CXX)

file(COPY
    "lua_to_ast.pl"
    "round2.lua"
    DESTINATION
      ${CMAKE_CURRENT_BINARY_DIR}
)

# vim: expandtab shiftwidth=4:
