#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Operators::AddWhitespace', *DATA );

__DATA__
## name: transform
1 and 1
1 and( 1 )
1 and ( 1 )
##-->
1 and 1
1 and ( 1 )
1 and ( 1 )
