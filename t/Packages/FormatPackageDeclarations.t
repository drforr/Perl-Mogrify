#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;
#-----------------------------------------------------------------------------

### name: Single package with no content
#package Foo;
#$a = "foo";
#package Bar;
#package Baz;
###-->
#class Foo{
#$a = "foo";
#};class Bar{
#};class Baz{};

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Packages::FormatPackageDeclarations', *DATA );

__DATA__
## name: Single package declaration
package Foo;
##-->
unit class Foo;
