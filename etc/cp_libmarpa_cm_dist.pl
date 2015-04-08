#!perl
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

# Copy things, being careful about timestamps.
#
# Right now the list of files is in a data section.
# I probably should make it an input file, and turn this
# into a general utility
#
# It makes more sense to do this in Perl than in the Makefile

use 5.010;
use strict;
use warnings;

use File::Spec;
use File::Copy;
use Getopt::Long;
use autodie;    # Portability not essential in this script

my $verbose;
my $stampfile;
GetOptions( "verbose|v" => \$verbose,
  "stamp=s" => \$stampfile
)
    or die("Error in command line arguments\n");

my $copy_count = 0;

FILE: while ( my $copy = <DATA> ) {
    chomp $copy;
    my ( $to, $from ) = $copy =~ m/\A (.*) [:] \s+ (.*) \z/xms;
    die "Bad copy spec: $copy" if not defined $to;
    die "From file does not exist: $from" if ! -e $from;
    next FILE if -e $to and ( -M $to <= -M $from );
    my ( undef, $to_dirs, $to_file ) = File::Spec->splitpath($to);
    my @to_dirs = File::Spec->splitdir($to_dirs);
    my @dir_found_so_far = ();
    # Make the directories we do not find
    DIR_PIECE: for my $dir_piece (@to_dirs) {
	push @dir_found_so_far, $dir_piece;
	my $dir_so_far = File::Spec->catdir(@dir_found_so_far);
        next DIR_PIECE if -e $dir_so_far;
	mkdir $dir_so_far;
    }
    File::Copy::copy($from, $to) or die "Cannot copy $from -> $to";
    $copy_count++;
    say "Copied $from -> $to" if $verbose;
} ## end FILE: while ( my $copy = <DATA> )

say "Files copied: $copy_count";

# If we have defined a stamp file, and we copied files
# or there is no stamp file, update it.
if ($stampfile and ($copy_count or not -e $stampfile)) {
   open my $stamp_fh, q{>}, $stampfile;
   say {$stamp_fh} "" . localtime;
   close $stamp_fh;
}

# Note that order DOES matter here -- files listed first
# will be copied first

__DATA__
components/libmarpa/marpa_ami.h: libmarpa/cm_dist/marpa_ami.h
components/libmarpa/modules/FindInline.cmake: libmarpa/cm_dist/modules/FindInline.cmake
components/libmarpa/modules/FindNullIsZeroes.cmake: libmarpa/cm_dist/modules/FindNullIsZeroes.cmake
components/libmarpa/modules/inline.c: libmarpa/cm_dist/modules/inline.c
components/libmarpa/error_codes.table: libmarpa/cm_dist/error_codes.table
components/libmarpa/marpa.c: libmarpa/cm_dist/marpa.c
components/libmarpa/steps.table: libmarpa/cm_dist/steps.table
components/libmarpa/marpa_tavl.c: libmarpa/cm_dist/marpa_tavl.c
components/libmarpa/README: libmarpa/cm_dist/README
components/libmarpa/LIB_VERSION.cmake: libmarpa/cm_dist/LIB_VERSION.cmake
components/libmarpa/marpa_tavl.h: libmarpa/cm_dist/marpa_tavl.h
components/libmarpa/marpa_ami.c: libmarpa/cm_dist/marpa_ami.c
components/libmarpa/config.h.cmake: libmarpa/cm_dist/config.h.cmake
components/libmarpa/marpa_obs.c: libmarpa/cm_dist/marpa_obs.c
components/libmarpa/COPYING: libmarpa/cm_dist/COPYING
components/libmarpa/CMakeLists.txt: libmarpa/cm_dist/CMakeLists.txt
components/libmarpa/include/marpa.h: libmarpa/cm_dist/include/marpa.h
components/libmarpa/marpa_avl.c: libmarpa/cm_dist/marpa_avl.c
components/libmarpa/COPYING.LESSER: libmarpa/cm_dist/COPYING.LESSER
components/libmarpa/marpa_avl.h: libmarpa/cm_dist/marpa_avl.h
components/libmarpa/events.table: libmarpa/cm_dist/events.table
components/libmarpa/marpa_obs.h: libmarpa/cm_dist/marpa_obs.h
