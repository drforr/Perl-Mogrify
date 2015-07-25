#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Rationals::FormatRationals', *DATA );

__DATA__
## name: transform
1.0;
my $x = 1.0 + 1.0;
1.;
1. if 1;
1. and 1;
1 if 1.;
1 and 1.;
my $x = 1. + 1.;
.1;
my $x = .1 + .1;
##-->
1.0;
my $x = 1.0 + 1.0;
1.0;
1.0 if 1;
1.0 and 1;
1 if 1.0;
1 and 1.0;
my $x = 1.0 + 1.0;
.1;
my $x = .1 + .1;
