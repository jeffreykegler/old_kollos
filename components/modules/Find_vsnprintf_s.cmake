MACRO(_VSNPRINTF_S)
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <stdio.h>
    #include <stdarg.h>
    int main()
    {
      char buffer[1024];
      _vsnprintf_s(&(buffer[0]), sizeof(buffer), sizeof(buffer) - 1, \"%s\", \"test\");
      return 0;
    }
    ")
  MESSAGE("-- Looking for _vsnprintf_s()")
  TRY_COMPILE(_VSNPRINTF_S_AVAILABLE ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(_VSNPRINTF_S_AVAILABLE)
    MESSAGE("-- Looking for _vsnprintf_s() - found")
    SET(HAVE__VSNPRINTF_S 1 CACHE STRING "_vsnprintf_s is available")
  ELSE()
    MESSAGE("-- Looking for _vsnprintf_s() - not found")
  ENDIF()
ENDMACRO()
_VSNPRINTF_S()
