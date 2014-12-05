# Module for locating Libmarpa.
#
# Cutomizable variables:
#   LIBMARPA_ROOT_DIR
#     This variable points to the Libmarpa root directory. On Windows the
#     library location typically will have to be provided explicitly using the
#     -D command-line option. Alternatively, an environment variable can be set.
#
# Read-Only variables:
#   LIBMARPA_FOUND
#     Indicates whether the library has been found.
#
#   LIBMARPA_INCLUDE_DIRS
#     Points to the LIBMARPA include directory.
#
#   LIBMARPA_LIBRARIES
#     Points to the LIBMARPA libraries that should be passed to
#     target_link_libararies.
#
# Copyright (c) 2014 Jean-Damien Durand
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Loosely based on FindICU.cmake
#
INCLUDE (CMakeParseArguments)
INCLUDE (FindPackageHandleStandardArgs)

SET (_LIBMARPA_POSSIBLE_DIRS
  ${LIBMARPA_ROOT_DIR}
  "$ENV{LIBMARPA_ROOT_DIR}"
  "C:/libmarpa"
  "$ENV{PROGRAMFILES}/libmarpa"
  "$ENV{PROGRAMFILES(X86)}/libmarpa")

SET (_LIBMARPA_POSSIBLE_INCLUDE_SUFFIXES include)
SET (_LIBMARPA_POSSIBLE_LIB_SUFFIXES lib)

FIND_PATH (LIBMARPA_ROOT_DIR
  NAMES include/marpa.h
  PATHS ${_LIBMARPA_POSSIBLE_DIRS}
  DOC "Libmarpa root directory")

IF (LIBMARPA_ROOT_DIR)
  # Re-use the previous path:
  FIND_PATH (LIBMARPA_INCLUDE_DIR
    NAMES marpa.h
    PATHS ${LIBMARPA_ROOT_DIR}
    PATH_SUFFIXES ${_LIBMARPA_POSSIBLE_INCLUDE_SUFFIXES}
    DOC "Libmarpa include directory"
    NO_DEFAULT_PATH)
ELSE (LIBMARPA_ROOT_DIR)
  # Use default path search
  FIND_PATH (LIBMARPA_INCLUDE_DIR
    NAMES marpa.h
    DOC "Libmarpa include directory"
    )
ENDIF (LIBMARPA_ROOT_DIR)

IF (LIBMARPA_INCLUDE_DIR)
  SET (_LIBMARPA_HEADER ${LIBMARPA_INCLUDE_DIR}/marpa.h)

  IF (EXISTS ${_LIBMARPA_HEADER})
    FILE (STRINGS ${_LIBMARPA_HEADER} _LIBMARPA_MAJOR_TMP REGEX "^#define MARPA.*MAJOR_VERSION[ \t]+[0-9]+[ \t]*$")
    FILE (STRINGS ${_LIBMARPA_HEADER} _LIBMARPA_MINOR_TMP REGEX "^#define MARPA.*MINOR_VERSION[ \t]+[0-9]+[ \t]*$")
    FILE (STRINGS ${_LIBMARPA_HEADER} _LIBMARPA_MICRO_TMP REGEX "^#define MARPA.*MICRO_VERSION[ \t]+[0-9]+[ \t]*$")

    STRING (REGEX REPLACE "^#define MARPA.*MAJOR_VERSION[ \t]+([0-9]+)[ \t]*$" "\\1" LIBMARPA_MAJOR_VERSION ${_LIBMARPA_MAJOR_TMP})
    STRING (REGEX REPLACE "^#define MARPA.*MINOR_VERSION[ \t]+([0-9]+)[ \t]*$" "\\1" LIBMARPA_MINOR_VERSION ${_LIBMARPA_MINOR_TMP})
    STRING (REGEX REPLACE "^#define MARPA.*MICRO_VERSION[ \t]+([0-9]+)[ \t]*$" "\\1" LIBMARPA_MICRO_VERSION ${_LIBMARPA_MICRO_TMP})

    SET (LIBMARPA_VERSION_COUNT 3)
    SET (_LIBMARPA_VERSION ${LIBMARPA_MAJOR_VERSION}.${LIBMARPA_MINOR_VERSION}.${LIBMARPA_MICRO_VERSION})
  ENDIF (EXISTS ${_LIBMARPA_HEADER})

  SET (_LIBMARPA_VERSION_PATTERN "[0-9]+\\.[0-9]+\\.[0-9]+")

  # Version sanity check
  IF ("${_LIBMARPA_VERSION}" MATCHES "${_LIBMARPA_VERSION_PATTERN}")
    SET (LIBMARPA_VERSION ${_LIBMARPA_VERSION})
  ELSE ()
    MESSAGE (WARNING "Cannot determine Libmarpa's version - ${_LIBMARPA_VERSION} does not match ${_LIBMARPA_VERSION_PATTERN}")
  ENDIF ()

  SET (_LIBMARPA_DETECTED_SUFFIX ${LIBMARPA_MAJOR_VERSION}${LIBMARPA_MINOR_VERSION})

ENDIF (LIBMARPA_INCLUDE_DIR)

IF (LIBMARPA_ROOT_DIR)
  FIND_LIBRARY (_LIBMARPA_LIBRARY NAMES marpa PATHS ${LIBMARPA_ROOT_DIR} PATH_SUFFIXES ${_LIBMARPA_POSSIBLE_LIB_SUFFIXES} NO_DEFAULT_PATH)
ELSE ()
  FIND_LIBRARY (_LIBMARPA_LIBRARY NAMES marpa PATH_SUFFIXES ${_LIBMARPA_POSSIBLE_LIB_SUFFIXES} )
ENDIF ()

IF (_LIBMARPA_LIBRARY)
  LIST (APPEND LIBMARPA_LIBRARIES ${_LIBMARPA_LIBRARY})
ENDIF ()

MARK_AS_ADVANCED (LIBMARPA_ROOT_DIR LIBMARPA_INCLUDE_DIR)

FIND_PACKAGE_HANDLE_STANDARD_ARGS (LIBMARPA REQUIRED_VARS LIBMARPA_INCLUDE_DIR LIBMARPA_LIBRARIES VERSION_VAR LIBMARPA_VERSION)

IF (LIBMARPA_VERSION)
  SET (LIBMARPA_FOUND 1 CACHE STRING "Libmarpa is found")
ENDIF ()

IF(LIBMARPA_FOUND)
  MESSAGE(STATUS "Found Libmarpa library        : Version ${LIBMARPA_VERSION}")
ENDIF()

MARK_AS_ADVANCED (LIBMARPA_FOUND)
