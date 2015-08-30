#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

TODO: {
    local $TODO = 'Need to refactor/rewrite transform_ok() for full modules';
    transform_ok( 'ModuleSpecific::Exporter', *DATA );
}

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
sub a is export(:MANDATORY :ALL) { }
sub b is export(:MANDATORY :ALL) { }
sub c is export(:ALL) { }
sub d { }
