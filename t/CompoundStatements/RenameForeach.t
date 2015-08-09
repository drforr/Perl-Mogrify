#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::RenameForeach', *DATA );

__DATA__
## name: transform
for( 1 ) { }
foreach( 1 ) { }
for ( 1 ) { }
foreach ( 1 ) { }
##-->
for( 1 ) { }
for( 1 ) { }
for ( 1 ) { }
for ( 1 ) { }
