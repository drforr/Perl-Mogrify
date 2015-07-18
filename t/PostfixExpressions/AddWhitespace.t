#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< all_transformers_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

all_transformers_ok(
    -transformers => [ 'PostfixExpressions::AddWhitespace' ]
);

#-----------------------------------------------------------------------------
# ensure we return true if this test is loaded by
# 20_transformers.t_without_optional_dependencies.t

1;

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
