CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(test C CXX)

add_test(simple_test ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/simple_test.lua)

# vim: expandtab shiftwidth=4:
