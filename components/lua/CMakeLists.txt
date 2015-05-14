#
# Lua 5.1.x
#
CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

project(lua C)

if("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
   message(SEND_ERROR "In-source builds are not allowed.")
   endif("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")


# ------------------
# Module search path
# ------------------
ENABLE_TESTING()

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)


#
# sub-folders
#
ADD_SUBDIRECTORY(src)

# ADD_SUBDIRECTORY(test)

