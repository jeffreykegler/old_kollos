# Copyright 2015 Jeffrey Kegler
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

.PHONY: clean code libmarpa verbose_test test

code:
	perl etc/cp_libmarpa_cm_dist.pl
	mkdir -p build
	cd build && cmake ../components && make VERBOSE=1

# NOT a dependency of code, for now
libmarpa:
	cd libmarpa && make test

verbose_test:
	# cd build && \
	# LUA_CPATH=';;../../build/main/lib?.so;../../build/main/cyg?.dll' \
	# LUA_PATH=';;../../build/main/?.lua' \
	  # ctest --output-on-failure --verbose

test:
	rm -rf do_test
	mkdir do_test
	cd do_test && cmake ../components/test && make VERBOSE=1
	LUA_CPATH=';;build/main/lib?.so;build/main/cyg?.dll' \
	 LUA_PATH=';;build/main/?.lua' \
	  prove -v --exec 'build/lua/src/lua' build/test/dev/*.lua
	  prove -v -Ibuild/pluif build/luif/lua_to_ast.pl

new_test:
	LUA_CPATH=';;build/main/lib?.so;build/main/cyg?.dll' \
	 LUA_PATH=';;build/main/?.lua' \
	  prove -v --exec 'build/lua/src/lua' build/test/luif/*.lua

clean:
	rm -rf build
	mkdir build

# vim: expandtab shiftwidth=4:
