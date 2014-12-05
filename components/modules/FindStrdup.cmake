MACRO(STRDUP)
  MESSAGE("-- Looking for _strdup()")
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <string.h>
    int main() {
        _strdup(\"test\");
        return 0;
    }
    ")
  try_compile(HAVE_STRDUP ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(HAVE_STRDUP)
    MESSAGE("-- Looking for _strdup() - found")
    SET(SYS_STRDUP_IS__STRDUP 1 CACHE STRING "strdup function")
    SET(SYS_STRDUP _strdup CACHE STRING "strdup function")
  else()
    MESSAGE("-- Looking for _strdup() - not found")
    MESSAGE("-- Looking for strdup()")
    write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
      "
      #include <string.h>
      int main() {
          strdup(\"test\");
          return 0;
      }
      ")
    try_compile(HAVE_STRDUP ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
    if(HAVE_STRDUP)
      MESSAGE("-- Looking for strdup() - found")
      SET(SYS_STRDUP_IS_STRDUP 1 CACHE STRING "strdup function")
      SET(SYS_STRDUP strdup CACHE STRING "strdup function")
    else()
      MESSAGE("-- Looking for strdup() - not found")
    endif()
  endif()
ENDMACRO()
STRDUP()
