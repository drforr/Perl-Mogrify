#!perl

use 5.006001;
use strict;
use warnings;

use Perl::ToPerl6::TransformerFactory;

use Test::More tests => 2;

#-----------------------------------------------------------------------------

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

# Choose two packages tha are required to run in a certain order:
#
# FormatMatchVariables changes $N to $N-1.
# FormatSpecialVariables changes $0 (which would have been $1 earlier)
# into $*PROGRAM-NAME.
#
# Therefore FormatSpecialVariables has to change $0 before it gets owerwritten.
#
my @unordered = map { $_->new } qw(
    Perl::ToPerl6::Transformer::Variables::FormatSpecialVariables
    Perl::ToPerl6::Transformer::Variables::FormatMatchVariables
);

my @ordered = Perl::ToPerl6::TransformerFactory::topological_sort( @unordered );
isa_ok $ordered[0],
       'Perl::ToPerl6::Transformer::Variables::FormatSpecialVariables',
       'FormatSpecialVariables runs first';
isa_ok $ordered[1],
       'Perl::ToPerl6::Transformer::Variables::FormatMatchVariables',
       'FormatMatchVariables runs first';

1;


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
