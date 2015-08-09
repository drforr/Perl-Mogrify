#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::FormatConditionals', *DATA );

__DATA__
## name: transform
if( 1 ) { }
if ( 1 ) { }
##-->
if ( 1 ) { }
if ( 1 ) { }
