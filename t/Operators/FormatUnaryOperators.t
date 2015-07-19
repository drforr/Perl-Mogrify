#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Operators::FormatUnaryOperators', *DATA );

__DATA__
## name: only unary operators should be affected.
1 ~ 3;
##-->
1 ~ 3;
## name: transform
~32;
~32 if 1;
~32 and 1;
1 if ~32;
1 and ~32;
!$x;
##-->
+^32;
+^32 if 1;
+^32 and 1;
1 if +^32;
1 and +^32;
?^$x;
