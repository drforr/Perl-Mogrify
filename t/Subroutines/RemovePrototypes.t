#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Subroutines::RemovePrototypes', *DATA );

__DATA__
## name: transform
sub { }
sub foo { }
sub foo($) { }
sub foo($a) { }
##-->
sub { }
sub foo { }
sub foo { }
sub foo($a) { }
