CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

enable_testing()

# You can tweak some common (for all subprojects) stuff here. For example:

SET (CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/modules")
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES  ON)

if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
  message(SEND_ERROR "In-source builds are not allowed.")
endif ()

# set(CMAKE_VERBOSE_MAKEFILE ON)
# set(CMAKE_COLOR_MAKEFILE   ON)

# Remove 'lib' prefix for shared libraries on Windows
if (WIN32)
  set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif ()

# NOTE: The order matters! The most independent ones should go first.
add_subdirectory(libmarpa) # static library
add_subdirectory(lua) # interpreter
# add_subdirectory(luabit) # Lua bit op library
add_subdirectory(main) # shared library
add_subdirectory(json) # a sample executable
add_subdirectory(test) # kollos-wide tests

# vim: expandtab shiftwidth=4:
