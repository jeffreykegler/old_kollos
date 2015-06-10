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

# Prototype the LUIF parser

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Scalar::Util;
use Data::Dumper;
use Test::More tests => 34;
use Fcntl;

## no critic (ErrorHandling::RequireCarping);
use Marpa::R2 3.0;

use LUIF;

my $luif_script = <<'EO_LUIF';

kollos.if('alpha')

seamless l0.E ::=
      number -> number
   || E ws? '*' ws? E -> E:1*E:2
   || E ws? '+' ws? E -> E:1+E:2
token ws ([\009\010\013\032]) -> nil
token l0.number ([%d]+)

EO_LUIF

sub flatten {
    my ( $result, $arg ) = @_;
    if ( not ref $arg ) {
        push @{$result}, $arg;
        return;
    }
    if ( ref $arg eq 'ARRAY' ) {
        flatten( $result, $_ ) for @{$arg};
        return;
    }
    if ( ref $arg eq 'REF' ) {
        flatten( $result, ${$arg} );
        return;
    }
    die "arg is ", ref $arg;
} ## end sub flatten

for my $test_data ([\$luif_script, 'test 1']) {
    my ($test_script_ref, $test_name) = @{$test_data};
    my $ast = LUIF::ast($test_script_ref);
    my $flat = [];
    flatten( $flat, $ast );
    my $output = join q{}, @{$flat};
    Test::More::is( ${$test_script_ref}, $output, $test_name );
}

# vim: expandtab shiftwidth=4:
