#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'PostfixExpressions::AddWhitespace', *DATA );

__DATA__
## name: transform
1 if 1
1 if( 1 )
1 if ( 1 )
1 unless 1
1 unless( 1 )
1 unless ( 1 )
1 while 1
1 while( 1 )
1 while ( 1 )
##-->
1 if 1
1 if ( 1 )
1 if ( 1 )
1 unless 1
1 unless ( 1 )
1 unless ( 1 )
1 while 1
1 while ( 1 )
1 while ( 1 )
