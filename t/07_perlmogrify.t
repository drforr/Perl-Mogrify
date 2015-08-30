#!perl

use 5.006001;
use strict;
use warnings;

use File::Spec;

use Test::More tests => 1;

#-----------------------------------------------------------------------------

my $perlmogrify = File::Spec->catfile( qw(blib script perlmogrify) );
if (not -e $perlmogrify) {
    $perlmogrify = File::Spec->catfile( qw(bin perlmogrify) )
}

require_ok($perlmogrify);

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/07_perlmogrify.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
