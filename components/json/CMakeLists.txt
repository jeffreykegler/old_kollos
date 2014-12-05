CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(json C CXX)

include_directories(${LIBMARPA_INCLUDE_DIRS})

add_executable(${PROJECT_NAME} json.c)

target_link_libraries(${PROJECT_NAME} libmarpa)

# vim: expandtab shiftwidth=4:
