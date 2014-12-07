CMAKE_MINIMUM_REQUIRED (VERSION 3.0)
PROJECT (marpa_wrapper C)

# ------------------
# Module search path
# ------------------
SET (CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/modules")
ENABLE_TESTING()

# ----------------------------------------------------------------------------
# Enable all warnings depending on compiler
# C.f. http://stackoverflow.com/questions/14231292/cmake-and-compiler-warnings
# ----------------------------------------------------------------------------
IF (CMAKE_COMPILER_IS_GNUCC)
    ADD_DEFINITIONS(-Wall)
ENDIF (CMAKE_COMPILER_IS_GNUCC)
IF (MSVC)
    ADD_DEFINITIONS(/W3)
ENDIF (MSVC)

# --------
# config.h
# --------
FIND_PACKAGE(Inline)
FIND_PACKAGE(Va_copy)
FIND_PACKAGE(Fileno)
FIND_PACKAGE(Write)
FIND_PACKAGE(NullIsZeroes)
FIND_PACKAGE(Strdup)
FIND_PACKAGE(Localtime_r)
FIND_PACKAGE(Localtime_s)
FIND_PACKAGE(_strerror_s)
FIND_PACKAGE(_vsnprintf_s)
INCLUDE(CheckIncludeFile)
CHECK_INCLUDE_FILE("sys/types.h" HAVE_SYS_TYPES_H)
CHECK_INCLUDE_FILE("sys/time.h" HAVE_SYS_TIME_H)
CHECK_INCLUDE_FILE("time.h" HAVE_TIME_H)
CHECK_INCLUDE_FILE("unistd.h" HAVE_UNISTD_H)
CHECK_INCLUDE_FILE("io.h" HAVE_IO_H)
CONFIGURE_FILE("${PROJECT_SOURCE_DIR}/include/marpa_wrapper_config.h.in" "${PROJECT_BINARY_DIR}/include/marpa_wrapper_config.h")

INCLUDE_DIRECTORIES ("${PROJECT_BINARY_DIR}/include" "${PROJECT_SOURCE_DIR}/include" ${libmarpa_INCLUDE_DIRS})

# ---------------------------
# General overwrite of CFLAGS
# ---------------------------
#
# Just turn tracing off, for now
ADD_DEFINITIONS(-DMARPAWRAPPER_NTRACE)

# -------------------------------------------------
# General output path for libraries and executables
# -------------------------------------------------
# SET (LIBRARY_OUTPUT_PATH "${PROJECT_BINARY_DIR}/build")
# SET (EXECUTABLE_OUTPUT_PATH "${PROJECT_BINARY_DIR}/build")

# ------------------------
# marpa_wrapper library
# ------------------------
FILE(GLOB marpa_wrapper_lib_src src/*.c include/*.h)
INCLUDE (GenerateExportHeader)
ADD_COMPILER_EXPORT_FLAGS ()

# Add PIC later
# Required on Unix OS family to be able to be linked into shared libraries.
# set_target_properties(${PROJECT_NAME}
#                      PROPERTIES POSITION_INDEPENDENT_CODE ON)

ADD_LIBRARY (marpa_wrapper STATIC
  ${marpa_wrapper_lib_src}
  ${libmarpa_BINARY_DIR}/config.h
  )

SET (MARPAWRAPPER_VERSION_MAJOR 0)
SET (MARPAWRAPPER_VERSION_MINOR 1)
SET (MARPAWRAPPER_VERSION_PATCH 1)
SET (MARPAWRAPPER_VERSION ${MARPAWRAPPER_VERSION_MAJOR}.${MARPAWRAPPER_VERSION_MINOR}.${MARPAWRAPPER_VERSION_PATCH})
SET_TARGET_PROPERTIES(marpa_wrapper PROPERTIES VERSION ${MARPAWRAPPER_VERSION} SOVERSION ${MARPAWRAPPER_VERSION_MAJOR})
GENERATE_EXPORT_HEADER(marpa_wrapper
  EXPORT_MACRO_NAME EXPORT
  EXPORT_FILE_NAME include/marpa_wrapper_Export.h
  DEPRECATED_MACRO_NAME DEPRECATED
  NO_EXPORT_MACRO_NAME NO_EXPORT
  STATIC_DEFINE STATIC
  NO_DEPRECATED_MACRO_NAME NO_DEPRECATED
  DEFINE_NO_DEPRECATED
  PREFIX_NAME MARPAWRAPPER_
)

# -----
# Tests
# -----
ADD_CUSTOM_TARGET(check COMMAND "${CMAKE_CTEST_COMMAND}")

# -----------
# Executables
# -----------
ADD_EXECUTABLE        (marpa_wrapper_test EXCLUDE_FROM_ALL test/marpa_wrapper_test.c)
TARGET_LINK_LIBRARIES (marpa_wrapper_test marpa_wrapper)
ADD_TEST              (marpa_wrapperTest marpa_wrapper_test)
ADD_DEPENDENCIES      (check marpa_wrapper_test)

# --------
# Bindings
# --------
FIND_PACKAGE(SWIG 3.0)
IF (SWIG_FOUND)
  ADD_CUSTOM_TARGET(bindings)
  # ---
  # Lua
  # ---
  FIND_PACKAGE(Lua 5.1)
  IF (LUA_INCLUDE_DIR)
    MESSAGE(STATUS "Lua include path: ${LUA_INCLUDE_DIR}")
    ADD_LIBRARY(marpa_wrapperLua MODULE EXCLUDE_FROM_ALL bindings/lua/marpa_wrapperLua.c)
    TARGET_LINK_LIBRARIES (marpa_wrapperLua marpa_wrapper)
    ADD_DEPENDENCIES(bindings marpa_wrapperLua)
    ADD_CUSTOM_COMMAND (
      PRE_BUILD
      COMMENT "Generating Lua Bindings"
      OUTPUT bindings/lua/marpa_wrapperLua.c
      COMMAND "${SWIG_EXECUTABLE}"
      #
      # SWIG support only ISO-C, so make the export be simply "extern" - has an effect only for generating the wrapper
      #
      ARGS -module marpa_wrapperLua -lua -nodefaultctor -nodefaultdtor -I../../include -I../../bindings -DMARPAWRAPPER_EXPORT=extern -o marpa_wrapperLua.c "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapper.i"
      DEPENDS marpa_wrapper "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapper.i" "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperDatavpOverwrite.i" "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperLanguagesMacros.i"  "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperLanguagesMacrosLua.i" "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperLanguagesMacrosPerl.i" "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperInnerCallbacksDeclarations.i" "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperInnerCallbacksDefinitions.i" "${PROJECT_SOURCE_DIR}/bindings/marpa_wrapperExtends.i"
      WORKING_DIRECTORY "bindings/lua"
      VERBATIM
      )
    SET_PROPERTY (TARGET marpa_wrapperLua APPEND_STRING PROPERTY INCLUDE_DIRECTORIES "${LUA_INCLUDE_DIR}")
  ENDIF ()
ENDIF ()

