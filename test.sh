#!/bin/sh
stamp=`date +%m%d%H%M%S`
errs="errs$stamp"
make test new_test 2>&1 | tee "$errs"
cp "$errs" errs.last
