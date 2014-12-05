MACRO(LOCALTIME_S)
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <time.h>
    int main()
    {
      time_t t;
      struct tm tm;
      (void)localtime_s(&tm, (const time_t *) &t);
      return 0;
    }
    ")
  MESSAGE("-- Looking for localtime_s()")
  try_compile(LOCALTIME_S_AVAILABLE ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(LOCALTIME_S_AVAILABLE)
    MESSAGE("-- Looking for localtime_s() - found")
    SET(HAVE_LOCALTIME_S 1 CACHE STRING "localtime_s is available")
  else()
    MESSAGE("-- Looking for localtime_s() - not found")
  endif()
ENDMACRO()
LOCALTIME_S()
