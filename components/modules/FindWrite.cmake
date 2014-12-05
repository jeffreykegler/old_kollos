MACRO(WRITE)
  MESSAGE("-- Looking for _write()")
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <io.h>
    int main() {
        _write(0, \"\", 0);
        return 0;
    }
    ")
  try_compile(HAVE_WRITE ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(HAVE_WRITE)
    MESSAGE("-- Looking for _write() - found")
    SET(SYS_WRITE_IS__WRITE 1 CACHE STRING "write function")
    SET(SYS_WRITE _write CACHE STRING "write function")
  else()
    MESSAGE("-- Looking for _write() - not found")
    MESSAGE("-- Looking for write()")
    write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
      "
      #include <stdio.h>
      int main() {
          write(0, \"\", 0);
          return 0;
      }
      ")
    try_compile(HAVE_WRITE ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
    if(HAVE_WRITE)
      MESSAGE("-- Looking for write() - found")
      SET(SYS_WRITE_IS_WRITE 1 CACHE STRING "write function")
      SET(SYS_WRITE write CACHE STRING "write function")
    else()
      MESSAGE("-- Looking for write() - not found")
    endif()
  endif()
ENDMACRO()
WRITE()
