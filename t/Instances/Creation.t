#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Instances::Creation', *DATA );

#
# new Foo 'bar'; --> Foo.new('bar'); # Foo.new 'bar' doesn't work.
#

__DATA__
## name: transformed
Foo->new();
new Foo();
new Foo::Bar();
new Foo ();
new Foo 'bar';
$item = new Parse::RecDescent::InterpLit($0,$lookahead,$line);
##-->
Foo->new();
Foo->new();
Foo::Bar->new();
Foo->new ();
Foo->new('bar');
$item = Parse::RecDescent::InterpLit->new($0,$lookahead,$line);
