#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 3;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Variables::ReplaceUndef', *DATA );

__DATA__
## name: stuff
$x = undef;
##-->
$x = Any;
## name: regression
undef $a{'a'};
undef $a->{'a'};
##-->
$a{'a'}:delete;
$a.{'a'}:delete;
