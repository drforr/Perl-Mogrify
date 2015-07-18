#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'CompoundStatements::FormatLoops', *DATA );

__DATA__
## name: test
for( @a ) { }
for( $i = 0; $i < 1; $i++ ) { }
for ( $i = 0; $i < 1; $i++ ) { }
##-->
for( @a ) { }
loop ( $i = 0; $i < 1; $i++ ) { }
loop ( $i = 0; $i < 1; $i++ ) { }
