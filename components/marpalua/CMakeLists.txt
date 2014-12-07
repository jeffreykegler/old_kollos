CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

PROJECT(marpalua C)

# ------------------
# Module search path
# ------------------
SET (CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/modules")
ENABLE_TESTING()

if("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
   message(SEND_ERROR "In-source builds are not allowed.")
   endif("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")

# ----------------------------------------------------------------------------
# Enable all warnings depending on compiler
# C.f. http://stackoverflow.com/questions/14231292/cmake-and-compiler-warnings
# ----------------------------------------------------------------------------
IF (CMAKE_COMPILER_IS_GNUCC)
    # MARPA_DEBUG_FLAG ?
    # -Wextra ?
    # -Wdeclaration-after-statement ?
    ADD_DEFINITIONS(-g -O2 -Wall -Wpointer-arith -Wstrict-prototypes -Wwrite-strings -Wshadow -Wmissing-declarations -Wconversion -ansi -pedantic)
    ADD_DEFINITIONS(-Wundef -Wendif-labels)
ENDIF (CMAKE_COMPILER_IS_GNUCC)
IF (MSVC)
    ADD_DEFINITIONS(/W3)
ENDIF (MSVC)

# --------
# config.h
# --------
FIND_PACKAGE(Inline)
FIND_PACKAGE(NullIsZeroes)
INCLUDE(CheckIncludeFile)
CHECK_INCLUDE_FILE("stdint.h" HAVE_STDINT_H)
CHECK_INCLUDE_FILE("inttypes.h" HAVE_INTTYPES_H)

SET(marpalua_src marpa_lua.c)

# Expose B's public includes (including Boost transitively) to other
# subprojects through cache variable.
set(${PROJECT_NAME}_INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/include
    CACHE INTERNAL "${PROJECT_NAME}: Include Directories" FORCE)

include_directories("${PROJECT_BINARY_DIR}")
target_link_libraries(${PROJECT_NAME} ${libmarpa_BINARY_DIR}/libmarpa.a)
ADD_LIBRARY(marpalua SHARED ${marpalua_src})

# vim: expandtab shiftwidth=4:
