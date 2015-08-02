#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Instances::Creation', *DATA );

__DATA__
## name: transformed
Foo->new();
new Foo();
##-->
Foo->new();
Foo->new();
