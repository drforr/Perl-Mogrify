#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

TODO: {
    local $TODO = 'Need to refactor/rewrite transform_ok() for full modules';
    transform_ok( 'ModuleSpecific::Moose', *DATA );
}

__DATA__
## name: from the perldoc
package Point;
use Moose;
has 'x' => (is => 'rw', isa => 'Int');
has 'y' => (is => 'rw', isa => 'Int');
sub clear {
    my $self = shift;
    $self->x(0);
    $self->y(0);
}
##-->
unit class Point;
#use Moose;
#has 'x' => (is => 'rw', isa => 'Int');
#has 'y' => (is => 'rw', isa => 'Int');
has Int $.x;
sub clear {
    my $self = shift;
    $.x = 0;
    $.y = 0;
}
## name: alternatives
package Point;
use Moose;
has( 'x', 'is', 'rw', 'isa', 'Int' );
sub clear {
    my $self = shift;
    $self->x(0);
    $self->y(0);
}
##-->
unit class Point;
#use Moose;
#has 'x' => (is => 'rw', isa => 'Int');
#has 'y' => (is => 'rw', isa => 'Int');
has Int $.x;
sub clear {
    my $self = shift;
    $.x = 0;
    $.y = 0;
}
