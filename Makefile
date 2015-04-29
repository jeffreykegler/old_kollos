

code:
	perl etc/cp_libmarpa_cm_dist.pl
	rm -rf build
	mkdir build
	cd build && cmake ../components && make VERBOSE=1

# NOT a dependency of code, for now
libmarpa:
	cd libmarpa && make test

verbose_test:
	cd build && \
	LUA_CPATH=';;../../build/main/lib?.so;../../build/main/cyg?.dll' \
	LUA_PATH=';;../../build/main/?.lua' \
	  ctest --output-on-failure --verbose

test:
	cd build && \
	LUA_CPATH=';;../../build/main/lib?.so;../../build/main/cyg?.dll' \
	LUA_PATH=';;../../build/main/?.lua' \
	  ctest --output-on-failure
