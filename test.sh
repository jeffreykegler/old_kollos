#!/bin/sh
stamp=`date +%m%d%H%M%S`
make test new_test 2>&1 | tee "errs$stamp"
