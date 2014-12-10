# This is totally non-portable.
# It relies on my personal directory structure on my main development box.
#  - Jeffrey
set -x
if test -d components/libmarpa
then
   rm -r components/libmarpa/*
else
   echo no components/libmarpa directory 1>&2
   exit 1
fi
(cd ../libmarpa/cm_dist && tar cvf - .) | \
  (cd components/libmarpa && tar xf -)
