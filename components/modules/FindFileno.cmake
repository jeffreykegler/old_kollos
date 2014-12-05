MACRO(FILENO)
  MESSAGE("-- Looking for _fileno()")
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <stdio.h>
    int main() {
        _fileno(stdin);
        return 0;
    }
    ")
  try_compile(HAVE__FILENO ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(HAVE__FILENO)
    MESSAGE("-- Looking for _fileno() - found")
    SET(SYS_FILENO_IS__FILENO 1 CACHE STRING "fileno function")
    SET(SYS_FILENO _fileno CACHE STRING "fileno function")
  else()
    MESSAGE("-- Looking for _fileno() - not found")
    MESSAGE("-- Looking for fileno()")
    write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
      "
      #include <stdio.h>
      int main() {
          fileno(stdin);
          return 0;
      }
      ")
    try_compile(HAVE_FILENO ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
    if(HAVE_FILENO)
      MESSAGE("-- Looking for fileno() - found")
      SET(SYS_FILENO_IS_FILENO 1 CACHE STRING "fileno function")
      SET(SYS_FILENO fileno CACHE STRING "fileno function")
    else()
      MESSAGE("-- Looking for fileno() - not found")
    endif()
  endif()
ENDMACRO()
FILENO()
