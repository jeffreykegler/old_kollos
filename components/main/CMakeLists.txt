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

FIND_PACKAGE(Lua51)
IF (LUA_INCLUDE_DIR)
  MESSAGE(STATUS "Lua include path: ${LUA_INCLUDE_DIR}")
  include_directories("${LUA_INCLUDE_DIR}")
ELSE ()
  message( FATAL_ERROR "Lua 5.1 not available.  Kollos cannot be built" )
ENDIF (LUA_INCLUDE_DIR)

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

ADD_CUSTOM_COMMAND (
  COMMENT "Writing kollos.c"
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/kollos.c
  COMMAND ${lua_INTERP}
      ${CMAKE_CURRENT_SOURCE_DIR}/kollos.c.lua 
      out=${CMAKE_CURRENT_BINARY_DIR}/kollos.c
      errors=${libmarpa_ERROR_CODES}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/kollos.c.lua ${libmarpa_ERROR_CODES}
  VERBATIM
  )


# Expose B's public includes (including Boost transitively) to other
# subprojects through cache variable.
set(${PROJECT_NAME}_INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/include
    CACHE INTERNAL "${PROJECT_NAME}: Include Directories" FORCE)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}")
include_directories("${libmarpa_SOURCE_DIR}/include")
ADD_LIBRARY(kollos_c SHARED ${CMAKE_CURRENT_BINARY_DIR}/kollos.c)
target_link_libraries(kollos_c ${libmarpa_BINARY_DIR}/libmarpa_s.a ${LUA_LIBRARIES})

# vim: expandtab shiftwidth=4:
