#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Pragmas::FormatConstants', *DATA );

__DATA__
## name: readonly
Readonly my $x => 1;
Readonly my @x => (1,2,3);
##-->
constant $x = 1;
constant @x = (1,2,3);
## name: constant
use constant X => 1;
use constant {
  Y => 1
};
##-->
constant X = 1;
constant {
  Y = 1
};
