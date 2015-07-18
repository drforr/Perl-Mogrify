#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'CompoundStatements::AddWhitespace', *DATA );

__DATA__
## name transform
## parms {}
## failures 0
## cut
if( 1 ) { }
if ( 1 ) { }
if( 1 ) { } elsif( 1 ) { }
if( 1 ) { } elsif ( 1 ) { }
#-->
if ( 1 ) { }
if ( 1 ) { }
if ( 1 ) { } elsif ( 1 ) { }
if ( 1 ) { } elsif ( 1 ) { }
