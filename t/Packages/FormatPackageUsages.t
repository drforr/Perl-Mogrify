#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Packages::FormatPackageUsages', *DATA );

__DATA__
## name: transformed
use Foo;
use Foo qw( a b );
##-->
use Foo:from<Perl5>;
use Foo:from<Perl5> qw( a b );
