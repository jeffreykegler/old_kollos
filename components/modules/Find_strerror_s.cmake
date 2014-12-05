MACRO(_STRERROR_S)
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <string.h>
    int main()
    {
      char buffer[1024];
      int errnum;
      _strerror_s(&(buffer[0]), sizeof(buffer) - 1, NULL);
      return 0;
    }
    ")
  MESSAGE("-- Looking for _strerror_s()")
  try_compile(_STRERROR_S_AVAILABLE ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(_STRERROR_S_AVAILABLE)
    MESSAGE("-- Looking for _strerror_s() - found")
    SET(HAVE__STRERROR_S 1 CACHE STRING "_strerror_s is available")
  else()
    MESSAGE("-- Looking for _strerror_s() - not found")
  endif()
ENDMACRO()
_STRERROR_S()
