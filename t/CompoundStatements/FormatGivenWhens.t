#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::FormatGivenWhens', *DATA );

__DATA__
## name: unchanged
given( 1 ) { }
given ( 1 ) { }
when( 1 ) { }
when ( 1 ) { }
##-->
given ( 1 ) { }
given ( 1 ) { }
when ( 1 ) { }
when ( 1 ) { }
