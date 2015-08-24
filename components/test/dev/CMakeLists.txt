CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(dev_tests C CXX)

file(COPY
    "json.lua"
    "simple3.lua"
    "simple_test2.lua"
    "simple_test.lua"
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
    )

# vim: expandtab shiftwidth=4:
