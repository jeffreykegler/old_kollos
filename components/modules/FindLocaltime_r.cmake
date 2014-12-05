MACRO(LOCALTIME_R)
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <time.h>
    int main()
    {
      time_t t;
      struct tm tm;
      (void)localtime_r(&t, &tm);
      return 0;
    }
    ")
  MESSAGE("-- Looking for localtime_r()")
  try_compile(LOCALTIME_R_AVAILABLE ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(LOCALTIME_R_AVAILABLE)
    MESSAGE("-- Looking for localtime_r() - found")
    SET(HAVE_LOCALTIME_R 1 CACHE STRING "localtime_r is available")
  else()
    MESSAGE("-- Looking for localtime_r() - not found")
  endif()
ENDMACRO()
LOCALTIME_R()
