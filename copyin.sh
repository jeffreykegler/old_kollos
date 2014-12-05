# This script "cheats" -- it assumes the specific
# locations of the Libmarpa and Kollos libraries on my current
# development machine.

# Assume the current directory is the top level directory
# of the Kollos repo
FROM=../libmarpa/cm_dist
TO=components/libmarpa
if test -d $FROM
then :
else
    echo $FROM does not exist 1>&2
    exit 1
fi
if test -d $TO
then :
else
    echo $TO does not exist 1>&2
    exit 1
fi
(cd $FROM && tar -cf - .) | (cd $TO && tar -xvf -)
