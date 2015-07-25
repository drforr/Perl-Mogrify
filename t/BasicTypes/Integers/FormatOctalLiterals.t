#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Integers::FormatOctalLiterals', *DATA );

__DATA__
## name: unchanged
001;
001 if 1;
001 and 1;
1 if 001;
1 and 001;
my $x= 001;
00167;
0010_10;
0_010_10;
##-->
:8<01>;
:8<01> if 1;
:8<01> and 1;
1 if :8<01>;
1 and :8<01>;
my $x= :8<01>;
:8<0167>;
:8<010_10>;
:8<010_10>;
