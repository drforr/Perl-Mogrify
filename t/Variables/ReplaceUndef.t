#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Variables::ReplaceUndef', *DATA );

__DATA__
## name: stuff
$x = undef;
##-->
$x = Any;
## name: regression
undef $a{'a'};
##-->
$a{'a'}:delete;
