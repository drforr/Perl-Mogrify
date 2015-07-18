#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Operators::FormatTernaryOperators', *DATA );

__DATA__
## name: transform
$x = $y > 1 ? 0 : 1;
$x = $y > 1 ? 0 : 1 if 1;
$x = $y > 1 ? 0 : 1 and 1;
1 if $x = $y > 1 ? 0 : 1;
1 and $x = $y > 1 ? 0 : 1;
##-->
$x = $y > 1 ?? 0 !! 1;
$x = $y > 1 ?? 0 !! 1 if 1;
$x = $y > 1 ?? 0 !! 1 and 1;
1 if $x = $y > 1 ?? 0 !! 1;
1 and $x = $y > 1 ?? 0 !! 1;
