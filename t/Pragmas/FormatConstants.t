#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Pragmas::FormatConstants', *DATA );

__DATA__
## name: readonly
Readonly my $x => 1;
Readonly our @x => (1,2,3);
##-->
my constant x = 1;
our constant x = (1,2,3);
## name: constant
use constant X => 1;
##-->
constant X = 1;
