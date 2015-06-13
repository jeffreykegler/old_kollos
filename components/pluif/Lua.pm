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

# A Lua parser

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Scalar::Util;
use Data::Dumper;
use Fcntl;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2 3.0;

package Lua;

use English qw( -no_match_vars );

$Lua::grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:default ::= action => [name,values]
lexeme default = latm => 1 action => [name,values]

# I attempt to follow the order of the Lua grammar in
# section 8 of the Lua 5.1 reference manual.
#
# Names which begin with "Lua" are taken directly from
# the Lua reference manual grammar.
<Lua chunk> ::= <Lua stat list> <Lua optional laststat>
<Lua stat list> ::= <Lua stat item>*
<Lua stat item> ::= <Lua stat> ';'
<Lua stat item> ::= <Lua stat>
<Lua optional laststat> ::= <Lua laststat> ';'
<Lua optional laststat> ::= <Lua laststat>
<Lua optional laststat> ::=

<Lua block> ::= <Lua chunk>

<Lua stat> ::= <Lua varlist> '=' <Lua explist>

<Lua stat> ::= <Lua functioncall>

<Lua stat> ::= <keyword do> <Lua block> <keyword end>

<Lua stat> ::= <keyword while> <Lua exp> <keyword do> <Lua block> <keyword end>

<Lua stat> ::= <keyword repeat> <Lua block> <keyword until> <Lua exp>

<Lua stat> ::= <keyword if> <Lua exp> <keyword then> <Lua block>
    <Lua elseif sequence> <Lua optional else block> <keyword end>
<Lua elseif sequence> ::= <Lua elseif sequence> <Lua elseif block>
<Lua elseif sequence> ::=
<Lua elseif block> ::= <keyword elseif> <Lua exp> <keyword then> <Lua block>
<Lua optional else block> ::= <keyword else> <Lua block>
<Lua optional else block> ::=

<Lua stat> ::= <keyword for> <Lua Name> '=' <Lua exp> ',' <Lua exp> ',' <Lua exp>
    <keyword do> <Lua block> <keyword end>
<Lua stat> ::= <keyword for> <Lua Name> '=' <Lua exp> ',' <Lua exp> <keyword do> <Lua block> <keyword end>

<Lua stat> ::= <keyword for> <Lua namelist> <keyword in> <Lua explist> <keyword do> <Lua block> <keyword end>

<Lua stat> ::= <keyword function> <Lua funcname> <Lua funcbody>

<Lua stat> ::= <keyword local> <keyword function> <Lua Name> <Lua funcbody>

<Lua stat> ::= <keyword local> <Lua namelist> <Lua optional namelist initialization>

<Lua optional namelist initialization> ::= 
<Lua optional namelist initialization> ::= '=' <Lua explist>

<Lua laststat> ::= <keyword return> <Lua optional explist>
<Lua laststat> ::= <keyword break>

<Lua optional explist> ::= 
<Lua optional explist> ::= <Lua explist>

<Lua funcname> ::= <Lua dotted name> <Lua optional colon name element>
<Lua dotted name> ::= <Lua Name>+ separator => [.] proper => 1
<Lua optional colon name element> ::=
<Lua optional colon name element> ::= ':' <Lua Name>

<Lua varlist> ::= <Lua var>+ separator => [,] proper => 1

<Lua var> ::= <Lua Name>
<Lua var> ::= <Lua prefixexp> '[' <Lua exp> ']'
<Lua var> ::= <Lua prefixexp> '.' <Lua Name>

<Lua namelist> ::= <Lua Name>+ separator => [,] proper => 1

<Lua explist> ::= <Lua exp>+ separator => [,] proper => 1

<Lua exp> ::=
       <Lua var>
     | '(' <Lua exp> ')' assoc => group
    || <Lua exp> <Lua args> assoc => right
    || <Lua exp> ':' <Lua Name> <Lua args> assoc => right
     | <keyword nil>
     | <keyword false>
     | <keyword true>
     | <Lua Number>
     | <Lua String>
     | '...'
     | <Lua tableconstructor>
     | <Lua function>
    || <Lua exp> '^' <Lua exp> assoc => right
    || <keyword not> <Lua exp>
     | '#' <Lua exp>
     | '-' <Lua exp>
    || <Lua exp> '*' <Lua exp>
     | <Lua exp> '/' <Lua exp>
     | <Lua exp> '%' <Lua exp>
    || <Lua exp> '+' <Lua exp>
     | <Lua exp> '-' <Lua exp>
    || <Lua exp> '..' <Lua exp> assoc => right
    || <Lua exp> '<' <Lua exp>
     | <Lua exp> '<=' <Lua exp>
     | <Lua exp> '>' <Lua exp>
     | <Lua exp> '>=' <Lua exp>
     | <Lua exp> '==' <Lua exp>
     | <Lua exp> '~=' <Lua exp>
    || <Lua exp> <keyword and> <Lua exp>
    || <Lua exp> <keyword or> <Lua exp>

<Lua prefixexp> ::= <Lua var>
<Lua prefixexp> ::= <Lua functioncall>
<Lua prefixexp> ::= '(' <Lua exp> ')'

<Lua functioncall> ::= <Lua prefixexp> <Lua args>
<Lua functioncall> ::= <Lua prefixexp> ':' <Lua Name> <Lua args>

<Lua args> ::= '(' <Lua optional explist> ')'
<Lua args> ::= <Lua tableconstructor>
<Lua args> ::= <Lua String>

<Lua function> ::= <keyword function> <Lua funcbody>

<Lua funcbody> ::= '(' <Lua optional parlist> ')' <Lua block> <keyword end>

<Lua optional parlist> ::= <Lua namelist> 
<Lua optional parlist> ::= <Lua namelist> ',' '...'
<Lua optional parlist> ::= '...'
<Lua optional parlist> ::= 

# A lone comma is not allowed in an empty fieldlist,
# apparently. This is why I use a dedicated rule
# for an empty table and a '+' sequence,
# instead of a '*' sequence.
<Lua tableconstructor> ::= '{' '}'
<Lua tableconstructor> ::= '{' <Lua fieldlist> '}'
<Lua fieldlist> ::= <Lua field>+ separator => [,;]

<Lua field> ::= '[' <Lua exp> ']' '=' <Lua exp>
<Lua field> ::= <Lua Name> '=' <Lua exp>
<Lua field> ::= <Lua exp>

:lexeme ~ <keyword and> priority => 1
<keyword and> ~ 'and'
:lexeme ~ <keyword break> priority => 1
<keyword break> ~ 'break'
:lexeme ~ <keyword do> priority => 1
<keyword do> ~ 'do'
:lexeme ~ <keyword else> priority => 1
<keyword else> ~ 'else'
:lexeme ~ <keyword elseif> priority => 1
<keyword elseif> ~ 'elseif'
:lexeme ~ <keyword end> priority => 1
<keyword end> ~ 'end'
:lexeme ~ <keyword false> priority => 1
<keyword false> ~ 'false'
:lexeme ~ <keyword for> priority => 1
<keyword for> ~ 'for'
:lexeme ~ <keyword function> priority => 1
<keyword function> ~ 'function'
:lexeme ~ <keyword if> priority => 1
<keyword if> ~ 'if'
:lexeme ~ <keyword in> priority => 1
<keyword in> ~ 'in'
:lexeme ~ <keyword local> priority => 1
<keyword local> ~ 'local'
:lexeme ~ <keyword nil> priority => 1
<keyword nil> ~ 'nil'
:lexeme ~ <keyword not> priority => 1
<keyword not> ~ 'not'
:lexeme ~ <keyword or> priority => 1
<keyword or> ~ 'or'
:lexeme ~ <keyword repeat> priority => 1
<keyword repeat> ~ 'repeat'
:lexeme ~ <keyword return> priority => 1
<keyword return> ~ 'return'
:lexeme ~ <keyword then> priority => 1
<keyword then> ~ 'then'
:lexeme ~ <keyword true> priority => 1
<keyword true> ~ 'true'
:lexeme ~ <keyword until> priority => 1
<keyword until> ~ 'until'
:lexeme ~ <keyword while> priority => 1
<keyword while> ~ 'while'

# multiline comments are discarded.  The lexer only looks for
# their beginning, and uses an event to throw away the rest
# of the comment
:discard ~ <singleline comment> event => 'singleline comment'
<singleline comment> ~ <singleline comment start>
<singleline comment start> ~ '--'

:discard ~ <multiline comment> event => 'multiline comment'
<multiline comment> ~ '--[' <optional equal signs> '['

<optional equal signs> ~ [=]*

:discard ~ whitespace
# Lua whitespace is locale dependant and so
# is Perl's, hopefully in the same way.
# Anyway, it will be close enough for the moment.
whitespace ~ [\s]+

# Good practice is to *not* use locale extensions for identifiers,
# and we enforce that,
# so all letters must be a-z or A-Z
<Lua Name> ~ <identifier start char> <optional identifier chars>
<identifier start char> ~ [a-zA-Z_]
<optional identifier chars> ~ <identifier char>*
<identifier char> ~ [a-zA-Z0-9_]

<Lua String> ::= <single quoted string>
<single quoted string> ~ ['] <optional single quoted chars> [']
<optional single quoted chars> ~ <single quoted char>*
# anything other than vertical space or a single quote
<single quoted char> ~ [^\v'\x5c]
<single quoted char> ~ '\' [\d\D] # also an escaped char

<Lua String> ::= <double quoted string>
<double quoted string> ~ ["] <optional double quoted chars> ["]
<optional double quoted chars> ~ <double quoted char>*
# anything other than vertical space or a double quote
<double quoted char> ~ [^\v"\x5c]
<double quoted char> ~ '\' [\d\D] # also an escaped char

<Lua String> ::= <multiline string>
:lexeme ~ <multiline string> pause => before event => 'multiline string'
<multiline string> ~ '[' <optional equal signs> '['

<Lua Number> ~ <hex number>
<Lua Number> ~ <C90 strtod decimal>
<Lua Number> ~ <C90 strtol hex>

<hex number> ~ '0x' <hex digit> <hex digit>
<hex digit> ~ [0-9a-fA-F]

# NuMeric representation in Lua is also not an
# exact science -- it is farmed out to the
# implementation's strtod() (for decimal)
# or strtoul() (for hex, if strtod failed).
# This is an attempt at the C90-conformant subset.
<C90 strtod decimal> ~ <optional sign> <decimal digits> <optional exponent>
<C90 strtod decimal> ~ <optional sign> <decimal digits> '.' <optional exponent>
<C90 strtod decimal> ~ <optional sign> '.' <decimal digits> <optional exponent>
<C90 strtod decimal> ~
    <optional sign> <decimal digits> '.' <decimal digits> <optional exponent>
<optional exponent> ~
<optional exponent> ~ [eE] <optional sign> <decimal digits>
<optional sign> ~
<optional sign> ~ [-+]
<C90 strtol hex> ~ [0] [xX] <hex digits>
<decimal digits> ~ [0-9]+
<hex digits> ~ [a-fA-F0-9]+

END_OF_SOURCE
    }
);

sub ast {
    my ($input_ref) = @_;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $Lua::grammar },
    # { trace_terminals => 99 }
    );

    my $input_length = length ${$input_ref};
    my $pos          = $recce->read($input_ref);

    READ: while (1) {

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};

            # say STDERR "Got $name";
            if ( $name eq 'multiline string' ) {
                my ( $start, $length ) = $recce->pause_span();
                my $string_terminator = $recce->literal( $start, $length );
                $string_terminator =~ tr/\[/\]/;
                my $terminator_pos =
                    index( ${$input_ref}, $string_terminator, $start );
                die "Died looking for $string_terminator"
                    if $terminator_pos < 0;

                # the string terminator has same length as the start of
                # string marker
                my $string_length = $terminator_pos + $length - $start;
                $recce->lexeme_read( 'multiline string',
                    $start, $string_length );
                $pos = $terminator_pos + $length;
                next EVENT;
            } ## end if ( $name eq 'multiline string' )
            if ( $name eq 'multiline comment' ) {
                # This is a discard event
                # say STDERR "multiline comment", join " ", @{$event};
                my ( undef, $start, $end ) = @{$event};
                my $length = $end-$start;
                my $comment_terminator = $recce->literal( $start, $length );
                $comment_terminator =~ tr/-//;
                $comment_terminator =~ tr/\[/\]/;
                my $terminator_pos =
                    index( ${$input_ref}, $comment_terminator, $start );
                die "Died looking for $comment_terminator"
                    if $terminator_pos < 0;

                # don't read anything into G1 -- just throw
                # the comment away
                $pos = $terminator_pos + $length;
                next EVENT;
            } ## end if ( $name eq 'multiline comment' )
            if ( $name eq 'singleline comment' ) {
                # This is a discard event
                # say STDERR "singleline comment", join " ", @{$event};
                my ( undef, $start, $end ) = @{$event};
                my $length = $end-$start;
                pos ${$input_ref} = $end-1;
                ${$input_ref} =~ /[\r\n]/gxms;
                my $new_pos = pos ${$input_ref};
                die "Died looking for singleline comment terminator"
                    if not defined $new_pos;
                $pos = $new_pos;
                # say STDERR "new pos is at ", substr(${$input_ref}, $new_pos, 20);
                next EVENT;
            } ## end if ( $name eq 'singleline comment' )
            die("Unexpected event");
        } ## end EVENT: for my $event ( @{ $recce->events() } )
        last READ if $pos >= $input_length;
        $pos = $recce->resume($pos);
        # my $eval_ok = eval { $pos = $recce->resume($pos); 1 };
        # if (not $eval_ok) {
            # say STDERR "===\n", $recce->show_progress(0, -1);
            # die $EVAL_ERROR;
        # }
    } ## end READ: while (1)

    if ( my $ambiguous_status = $recce->ambiguous() ) {
        Marpa::R2::exception( "The Lua source is ambiguous\n",
            $ambiguous_status );
    }

    return $recce->value();

} ## end sub ast

# vim: expandtab shiftwidth=4:
