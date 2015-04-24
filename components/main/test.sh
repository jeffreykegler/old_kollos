set -x
lua wrapper_gen.lua > junk.c &&
gcc -c -g \
  -Wall -Wpointer-arith -Wstrict-prototypes -Wwrite-strings -Wshadow -Wmissing-declarations -Wconversion -ansi -pedantic \
  -Wno-unused-function \
  -I/usr/include/lua5.1 -I../../libmarpa/work/public junk.c
