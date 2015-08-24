#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::RewriteLoops', *DATA );

__DATA__
## name: test
for( @a ) { }
for( $i = 0; $i < 1; $i++ ) { }
for ( $i = 0; $i < 1; $i++ ) { }
##-->
for( @a ) { }
loop ( $i = 0; $i < 1; $i++ ) { }
loop ( $i = 0; $i < 1; $i++ ) { }
