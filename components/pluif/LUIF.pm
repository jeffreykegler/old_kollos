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
use Fcntl;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2 3.0;

package LUIF;

$LUIF::grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:default ::= action => [values]
lexeme default = latm => 1

<LUIF piece sequence> ::= <LUIF piece>*
<LUIF piece> ::= <marked LUIF rule> | <Lua token>
<marked LUIF rule> ::= '(' <marked LUIF rule> ')'
<marked LUIF rule> ::= <LUIF rule>
<LUIF rule> ::= <LUIF rule beginning> <LUIF rule rhs>
<LUIF rule beginning> ::= <start keyword> <marked lhs> '::='
<LUIF rule beginning> ::= <rule keyword> <marked lhs> '::='
<LUIF rule beginning> ::= <marked lhs> '::='
<LUIF rule beginning> ::= <seamless keyword> <marked lhs> '~'
<LUIF rule beginning> ::= <lexeme keyword> <marked lhs> '~'
<LUIF rule beginning> ::= <token keyword> <marked lhs> '~'
<LUIF rule beginning> ::= <marked lhs> '~'

:lexeme ~ <start keyword>
<start keyword> ~ 'start'
:lexeme ~ <rule keyword>
<rule keyword> ~ 'rule'
:lexeme ~ <seamless keyword>
<seamless keyword> ~ 'seamless'
:lexeme ~ <lexeme keyword>
<lexeme keyword> ~ 'lexeme'
:lexeme ~ <token keyword>
<token keyword> ~ 'token'

<marked lhs> ::= '(' <marked lhs>  ')'
<marked lhs> ::= <lhs>

<lhs> ::= <LUIF Name>
<LUIF Name> ~ <LUIF Name start char> <optional LUIF Name chars>
<LUIF Name start char> ~ [a-zA-Z_]
<optional LUIF Name chars> ~ <LUIF Name char>*
<LUIF Name char> ~ [a-zA-Z0-9_]

<LUIF rule rhs> ::= '(' <LUIF rule rhs> ')'
<LUIF rule rhs> ::= <precedence levels>
<precedence levels> ::= <precedence levels> '||' <alternatives>
<precedence levels> ::= <alternatives>
<alternatives> ::= <alternatives> '|' <alternative>
<alternatives> ::= <alternative>
<alternative> ::= <filled alternative> | <empty alternative>
<filled alternative> ::= <rhs items> <optional LUIF action> <marked LUIF adverbs>
<empty alternative> ::= <optional LUIF action> <marked LUIF adverbs>
# eventually RHS items include charclasses and strings
<rhs items> ::= <rhs item>+
<rhs item> ::= <quantified rhs item>
<rhs item> ::= <LUIF symbol identifier>
<quantified rhs item> ::= <rhs item> <quantifier>
<quantified rhs item> ::= '(' <rhs item> ')' <quantifier>
<quantifier> ::= <quantifier proper> <optional punctuation specifier>
<quantifier proper> ::= '?' | '*' | '+'
<optional punctuation specifier> ::= <punctuation specifier>
<punctuation specifier> ::= <punctuation operator> <punctuator specifier>
<punctuation operator> ::= '%' | '%%' | '%-' | '%$'
<punctuator specifier> ::= <punctuator item>
<punctuator specifier> ::= '(' <punctuator item sequence> ')'
<punctuator item sequence> ::= <punctuator item sequence> <punctuator item>
<punctuator item sequence> ::= <punctuator item>
# eventually punctuation items include charclasses and strings
<punctuator item> ::= <LUIF symbol identifier>

# As of now, they are equivalent
<LUIF symbol identifier> ::= <Lua Name>

<optional LUIF action> ::= # empty
<optional LUIF action> ::= '->' <Lua exp>
<optional LUIF action> ::= '{' <Lua block> '}'

<marked LUIF adverbs> ::= <marked LUIF adverb>*
<marked LUIF adverb> ::= '(' 'empty' '=>' boolean ')' # empty adverb
<boolean> ::= 'true' | 'false'

<Lua token> ::= <singleline comment>
<Lua token> ::= whitespace
<Lua token> ::= <Lua Name>
<Lua token> ::= <Lua Number>
<Lua token> ::= <Lua String>
<Lua token> ::= '-'
<Lua token> ::= '+'
<Lua token> ::= '*'
<Lua token> ::= '/'
<Lua token> ::= '%'
<Lua token> ::= '^'
<Lua token> ::= '#'
<Lua token> ::= '=='
<Lua token> ::= '~='
<Lua token> ::= '<='
<Lua token> ::= '>='
<Lua token> ::= '<'
<Lua token> ::= '>'
<Lua token> ::= '='
<Lua token> ::= '('
<Lua token> ::= ')'
<Lua token> ::= '{'
<Lua token> ::= '}'
<Lua token> ::= '['
<Lua token> ::= ']'
<Lua token> ::= ';'
<Lua token> ::= ':'
<Lua token> ::= ','
<Lua token> ::= '.'
<Lua token> ::= '..'
<Lua token> ::= '...'

# Good practice is to *not* use locale extensions for identifiers,
# and we enforce that,
# so all letters must be a-z or A-Z
<Lua Name> ~ <identifier start char> <optional identifier chars>
<identifier start char> ~ [a-zA-Z_]
<optional identifier chars> ~ <identifier char>*
<identifier char> ~ [a-zA-Z0-9_]

# \x5b (opening square bracket) is OK unless two of them
# are in the first two positions
# empty comment is single line
<singleline comment> ::= <singleline comment start> <singleline comment trailer>
<singleline comment start> ~ '--'
<singleline comment trailer> ~ <optional comment body chars> <comment eol>
<optional comment body chars> ~ <comment body char>*
<comment body char> ~ [^\r\012]
<comment eol> ~ [\r\012]

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

<Lua token> ::= <multiline comment>
:lexeme ~ <multiline comment> pause => before event => 'multiline comment'
<multiline comment> ~ '--[' <optional equal signs> '['

<optional equal signs> ~ [=]*

# Lua whitespace is locale dependant and so
# is Perl's, hopefully in the same way.
# Anyway, it will be close enough for the moment.
whitespace ~ [\s]+

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

# The Lua grammar, adapted for LUIF actions and events
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

<Lua stat> ::= 'do' <Lua block> 'end'

<Lua stat> ::= 'while' <Lua exp> 'do' <Lua block> 'end'

<Lua stat> ::= 'repeat' <Lua block> 'until' <Lua exp>

<Lua stat> ::= 'if' <Lua exp> 'then' <Lua elseif sequence> <Lua optional else block> 'end'
<Lua elseif sequence> ::= <Lua elseif sequence> <Lua elseif block>
<Lua elseif sequence> ::=
<Lua elseif block> ::= 'elseif' <Lua exp> 'then' <Lua block>
<Lua optional else block> ::= 'else' <Lua block>
<Lua optional else block> ::=

<Lua stat> ::= 'for' <Lua Name> '=' <Lua exp> ',' <Lua exp> ',' <Lua exp>
    'do' <Lua block> 'end'
<Lua stat> ::= 'for' <Lua Name> '=' <Lua exp> ',' <Lua exp> 'do' <Lua block> 'end'

<Lua stat> ::= 'for' <Lua namelist> 'in' <Lua explist> 'do' <Lua block> 'end'

<Lua stat> ::= 'function' <Lua funcname> <Lua funcbody>

<Lua stat> ::= 'local' 'function' <Lua Name> <Lua funcbody>

<Lua stat> ::= 'local' <Lua namelist> <Lua optional explist>

<Lua optional explist> ::= 
<Lua optional explist> ::= <Lua explist>

<Lua laststat> ::= 'return' <Lua optional explist>
<Lua laststat> ::= 'break'

<Lua funcname> ::= <Lua dotted name> <Lua optional colon name element>
<Lua dotted name> ::= <Lua Name>+ separator => [.] proper => 0
<Lua optional colon name element> ::=
<Lua optional colon name element> ::= ':' <Lua Name>

<Lua varlist> ::= <Lua var>+ separator => [,] proper => 0

<Lua var> ::= <Lua Name>
<Lua var> ::= <Lua prefixexp> '[' <Lua exp> ']'
<Lua var> ::= <Lua prefixexp> '.' <Lua Name>

<Lua namelist> ::= <Lua Name>+ separator => [,] proper => 0

<Lua explist> ::= <Lua exp>+ separator => [,] proper => 0

<Lua exp> ::= 'nil'
<Lua exp> ::= 'false'
<Lua exp> ::= 'true'
<Lua exp> ::= <Lua Number>
<Lua exp> ::= <Lua String>
<Lua exp> ::= '...'
<Lua exp> ::= <Lua function>
<Lua exp> ::= <Lua prefixexp>
<Lua exp> ::= <Lua tableconstructor>
<Lua exp> ::= <Lua exp> <Lua binop> <Lua exp>
<Lua exp> ::= <Lua exp> <Lua unop> <Lua exp>

<Lua prefixexp> ::= <Lua var>
<Lua prefixexp> ::= <Lua functioncall>
<Lua prefixexp> ::= '(' <Lua exp> ')'

<Lua functioncall> ::= <Lua prefixexp> <Lua args>
<Lua functioncall> ::= <Lua prefixexp> ':' <Lua Name> <Lua args>

<Lua args> ::= '(' <Lua optional explist> ')'
<Lua args> ::= <Lua tableconstructor>
<Lua args> ::= <Lua String>

<Lua function> ::= 'function' <Lua funcbody>

<Lua funcbody> ::= '(' <Lua optional parlist> ')' <Lua block> 'end'

<Lua optional parlist> ::= <Lua namelist> 
<Lua optional parlist> ::= <Lua namelist> ',' '...'
<Lua optional parlist> ::= '...'

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

<Lua binop> ::= '+' | '-' | '*' | '/' | '^' | '%' | '..' |
    '<' | '<=' | '>' | '>=' | '==' | '~=' |
    'and' | 'or'

<Lua unop> ::= '-' | 'not' | '#'

END_OF_SOURCE
    }
);

sub ast {
    my ($input_ref) = @_;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $LUIF::grammar } );

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
                my ( $start, $length ) = $recce->pause_span();
                my $comment_terminator = $recce->literal( $start, $length );
                $comment_terminator =~ tr/-//;
                $comment_terminator =~ tr/\[/\]/;
                my $terminator_length = length $comment_terminator;
                my $terminator_pos =
                    index( ${$input_ref}, $comment_terminator, $start );
                die "Died looking for $comment_terminator"
                    if $terminator_pos < 0;

                # the comment terminator has same length as the start of
                # comment marker
                my $comment_length =
                    $terminator_pos + $terminator_length - $start;
                $recce->lexeme_read( 'multiline comment',
                    $start, $comment_length );
                $pos = $terminator_pos + $length;
                next EVENT;
            } ## end if ( $name eq 'multiline comment' )
            die("Unexpected event");
        } ## end EVENT: for my $event ( @{ $recce->events() } )
        last READ if $pos >= $input_length;
        $pos = $recce->resume($pos);
    } ## end READ: while (1)

    return $recce->value();

} ## end sub ast

# vim: expandtab shiftwidth=4:
