CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(test C CXX)

add_test(simple_test ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/simple_test.lua)
add_test(simple_test2 ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/simple_test2.lua)
add_test(simple3 ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/simple3.lua)
add_test(json ${lua_INTERP} ${CMAKE_CURRENT_SOURCE_DIR}/json.lua)

# vim: expandtab shiftwidth=4:
