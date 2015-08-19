#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 3;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Builtins::Rename', *DATA );

__DATA__
## name: transform
eval {};
eval "";
##-->
EVAL {};
EVAL "";
