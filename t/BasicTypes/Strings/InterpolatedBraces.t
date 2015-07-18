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
## name: Unicode character names
"\N{LATIN CAPITAL LETTER X}";
##-->
"\c[LATIN CAPITAL LETTER X]";
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
print OUT "{\n";
"x\}";
"\{x\}";
"$\{x";
