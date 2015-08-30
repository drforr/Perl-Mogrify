#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 3;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'ModuleSpecific::Exporter', *DATA );

#
# new Foo 'bar'; --> Foo.new('bar'); # Foo.new 'bar' doesn't work.
#

__DATA__
## name: from the perldoc
package MyModule;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = ( 'a', 'b' );
@EXPORT_OK = ( 'c' );
%EXPORT_TAGS = ( :all => [ 'a', 'b', 'c' ] );
sub a { }
sub b { }
sub c { }
sub d { }
##-->
package MyModule;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = ( 'a', 'b' )
sub a is export(:MANDATORY) { }
sub b is export(:MANDATORY) { }
sub c is export { }
sub d { }
