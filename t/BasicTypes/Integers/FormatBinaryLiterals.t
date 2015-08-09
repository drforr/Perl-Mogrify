#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'BasicTypes::Integers::FormatBinaryLiterals', *DATA );

__DATA__
## name: transform
0b01;
0b01 if 1;
0b01 and 1;
1 if 0b01;
1 and 0b01;
my $x = 0b01;
0b0101;
0b010_10;
0b_010_10;
##-->
:2<01>;
:2<01> if 1;
:2<01> and 1;
1 if :2<01>;
1 and :2<01>;
my $x = :2<01>;
:2<0101>;
:2<010_10>;
:2<010_10>;
