#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 3;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

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
#Internals::SVReadonly(%sv,1);
#sub %sv() { }
#const my %sv = 1;
#my const %sv = 1; # Reini
#my %sv :const = 1; # Reini
##-->
constant X = 1;
#Internals::SVReadonly(%sv,1);
#sub %sv() { }
#const my %sv = 1;
#my const %sv = 1; # Reini
#my %sv :const = 1; # Reini
