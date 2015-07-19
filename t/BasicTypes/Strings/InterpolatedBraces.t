#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::InterpolatedBraces', *DATA );

__DATA__
## name: Unaltered
"Hello (cruel?) world! $x <= $y[2] + 1"
##-->
"Hello (cruel?) world! $x <= $y[2] + 1"
## name: Special cases
"\N{LATIN CAPITAL LETTER X}";
"a\N{LATIN CAPITAL LETTER X}b";
"\x{12ab}";
"a\x{12ab}b";
##-->
"\c[LATIN CAPITAL LETTER X]";
"a\c[LATIN CAPITAL LETTER X]b";
"\x[12ab]";
"a\x[12ab]b";
## name: interpolation of bracketed variables
"${x}";
qq{${x}};
"\${x}";
##-->
"{$x}";
qq{{$x}};
"\$\{x\}";
## name: uninterpolated braces
"{x";
print OUT "{\n";
"x}";
"{x}";
"${x";
##-->
"\{x";
print OUT "\{\n";
"x\}";
"\{x\}";
"$\{x";
## name: escaped braces
"$\{x\}"
##-->
"$\{x\}"
## name: hash key
"$x{a}"
"$x{a}{b}"
"$x{a}[1]"
"$x{'a'}"
"$x->{'a'}"
##-->
"$x{'a'}"
"$x{'a'}{'b'}"
"$x{'a'}[1]"
"$x{'a'}"
"$x.{'a'}"
## name: array index
"$x[1]"
"$x[1]{a}"
##-->
"$x[1]"
"$x[1]{'a'}"
