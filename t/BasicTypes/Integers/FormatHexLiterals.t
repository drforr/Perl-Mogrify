#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Integers::FormatHexLiterals', *DATA );

__DATA__
## name: transform
0x01;
0x01 if 1;
0x01 and 1;
1 if 0x01;
1 and 0x01;
my $x = 0x01;
0x01ef;
0x010_ab;
0x_010_ab;
##-->
:16<01>;
:16<01> if 1;
:16<01> and 1;
1 if :16<01>;
1 and :16<01>;
my $x = :16<01>;
:16<01ef>;
:16<010_ab>;
:16<010_ab>;
