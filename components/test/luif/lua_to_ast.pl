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

use Lua;

sub slurp_file {

    my ($file_name) = @_;

    my $buf     = q{};
    my $buf_ref = \$buf;

    my $mode = O_RDONLY;

    local (*FH);
    sysopen( FH, $file_name, $mode )
        or die "Can't open $file_name: $!";

    my $size_left = -s FH;

    while ( $size_left > 0 ) {

        my $read_cnt =
            sysread( FH, ${$buf_ref}, $size_left, length ${$buf_ref} );

        unless ($read_cnt) {

            die "read error in file $file_name: $!";
            last;
        }

        $size_left -= $read_cnt;
    } ## end while ( $size_left > 0 )

    return $buf_ref;
} ## end sub slurp_file

my @test_files = qw(
    components/lua/etc/strict.lua
    components/lua/test/life.lua
    components/lua/test/xd.lua
    components/lua/test/printf.lua
    components/lua/test/env.lua
    components/lua/test/trace-calls.lua
    components/lua/test/fib.lua
    components/lua/test/echo.lua
    components/lua/test/luac.lua
    components/lua/test/sieve.lua
    components/lua/test/bisect.lua
    components/lua/test/fibfor.lua
    components/lua/test/sort.lua
    components/lua/test/table.lua
    components/lua/test/readonly.lua
    components/lua/test/cf.lua
    components/lua/test/hello.lua
    components/lua/test/trace-globals.lua
    components/lua/test/factorial.lua
    components/lua/test/globals.lua
    components/main/wrapper_gen.lua
    components/main/kollos/location.lua
    components/main/kollos/inspect.lua
    components/main/kollos/lo_g.lua
    components/main/kollos/unindent.lua
    components/main/kollos/main.lua
    components/main/kollos/util.lua
    components/main/kollos/wrap.lua
    components/main/kollos.lua
    components/main/kollos.c.lua
    components/test/dev/simple3.lua
    components/test/dev/simple_test.lua
    components/test/dev/json.lua
    components/test/dev/simple_test2.lua
);

for my $test_file (@test_files) {
    my $input_ref = slurp_file($test_file);
    my $ast = Lua::ast($input_ref);
    Test::More::pass( $test_file );
}

# vim: expandtab shiftwidth=4:
