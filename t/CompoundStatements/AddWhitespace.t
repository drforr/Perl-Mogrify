#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 4;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::AddWhitespace', *DATA );

__DATA__
## name: if-elsif
if( 1 ){ }
if( 1 ) { }
if ( 1 ) { }
if( 1 ) { } elsif( 1 ) { }
if( 1 ) { } elsif ( 1 ) { }
##-->
if ( 1 ){ }
if ( 1 ) { }
if ( 1 ) { }
if ( 1 ) { } elsif ( 1 ) { }
if ( 1 ) { } elsif ( 1 ) { }
## name: given-when
given( 1 ) { }
given ( 1 ) { }
when( 1 ) { }
when ( 1 ) { }
##-->
given ( 1 ) { }
given ( 1 ) { }
when ( 1 ) { }
when ( 1 ) { }
## name: until
until( 1 ) { }
until ( 1 ) { }
##-->
until ( 1 ) { }
until ( 1 ) { }
