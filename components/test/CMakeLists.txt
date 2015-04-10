CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(test C CXX)

SET (CTEST_ENVIRONMENT "
LUA_PATH=;;../../build/main/?.lua
LUA_CPATH=;;../../build/main/lib?.so
")

add_test(simple_test ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/test.lua)

# vim: expandtab shiftwidth=4:
