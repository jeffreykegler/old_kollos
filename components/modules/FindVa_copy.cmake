MACRO(VA_COPY)
  MESSAGE("-- Looking for __va_copy()")
  write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
    "
    #include <stdlib.h>
    #include <stdarg.h>
    void f (int i, ...) {
        va_list args1, args2;
        va_start (args1, i);
        __va_copy (args2, args1);
        if (va_arg (args2, int) != 42 || va_arg (args1, int) != 42)
            exit (1);
        va_end (args1); va_end (args2);
    }
    int main() {
        f (0, 42);
        return 0;
    }
    ")
  try_compile(HAVE___VA_COPY ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
  if(HAVE___VA_COPY)
    MESSAGE("-- Looking for __va_copy() - found")
    SET(SYS_VA_COPY_IS___VA_COPY 1 CACHE STRING "va_copy function")
    SET(SYS_VA_COPY __va_copy CACHE STRING "va_copy function")
  else()
    MESSAGE("-- Looking for __va_copy() - not found")
    MESSAGE("-- Looking for _va_copy()")
    write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
      "
      #include <stdlib.h>
      #include <stdarg.h>
      void f (int i, ...) {
          va_list args1, args2;
          va_start (args1, i);
          _va_copy (args2, args1);
          if (va_arg (args2, int) != 42 || va_arg (args1, int) != 42)
              exit (1);
          va_end (args1); va_end (args2);
      }
      int main() {
          f (0, 42);
          return 0;
      }
      ")
    try_compile(HAVE__VA_COPY ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
    if(HAVE__VA_COPY)
      MESSAGE("-- Looking for _va_copy() - found")
      SET(SYS_VA_COPY_IS__VA_COPY 1 CACHE STRING "va_copy function")
      SET(SYS_VA_COPY _va_copy CACHE STRING "va_copy function")
    else()
      MESSAGE("-- Looking for _va_copy() - not found")
      MESSAGE("-- Looking for va_copy()")
      write_file("${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c"
        "
        #include <stdlib.h>
        #include <stdarg.h>
        void f (int i, ...) {
            va_list args1, args2;
            va_start (args1, i);
            va_copy (args2, args1);
            if (va_arg (args2, int) != 42 || va_arg (args1, int) != 42)
                exit (1);
            va_end (args1); va_end (args2);
        }
        int main() {
            f (0, 42);
            return 0;
        }
        ")
      try_compile(HAVE_VA_COPY ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/cmake_try_compile.c)
      if(HAVE_VA_COPY)
        MESSAGE("-- Looking for va_copy() - found")
        SET(SYS_VA_COPY_IS_VA_COPY 1 CACHE STRING "va_copy function")
        SET(SYS_VA_COPY va_copy CACHE STRING "va_copy function")
      else()
        MESSAGE("-- Looking for va_copy() - not found")
      endif()
    endif()
  endif()
ENDMACRO()
VA_COPY()
