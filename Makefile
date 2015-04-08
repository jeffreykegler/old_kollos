

code:
	rm -rf build
	mkdir build
	cd build && cmake ../components && make VERBOSE=1

# NOT a dependency of code, for now
libmarpa:
	cd libmarpa && make test

test:
	cd build && ctest --output-on-failure
