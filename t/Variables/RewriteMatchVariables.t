#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Variables::RewriteMatchVariables', *DATA );

#-----------------------------------------------------------------------------
__DATA__
## name: transform
print $1;
$99 if 2;
##-->
print $0;
$98 if 2;
