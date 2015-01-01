

code:
	rm -rf build
	mkdir build
	cd build && cmake ../components && make VERBOSE=1

test:
	cd build && ctest --output-on-failure
