#!perl

# Self-compliance tests

use strict;
use warnings;

use English qw( -no_match_vars );

use File::Spec qw();

use Perl::Mogrify::Utils qw{ :characters };
use Perl::Mogrify::TestUtils qw{ starting_points_including_examples };

# Note: "use PolicyFactory" *must* appear after "use TestUtils" for the
# -extra-test-transformers option to work.
use Perl::Mogrify::PolicyFactory (
    '-test' => 1,
    '-extra-test-transformers' => [ qw{ ErrorHandling::RequireUseOfExceptions } ],
);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

use Test::Perl::Mogrify;

#-----------------------------------------------------------------------------

# Fall over if P::C::More isn't installed.
use Perl::Mogrify::Transformer::ErrorHandling::RequireUseOfExceptions;

#-----------------------------------------------------------------------------
# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require PPI::Cache;
    my $cache_path =
        File::Spec->catdir(
            File::Spec->tmpdir,
            "test-perl-mogrify-cache-$ENV{USER}",
        );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Strict object testing -- prevent direct hash key access

use Devel::EnforceEncapsulation;
foreach my $pkg ( $EMPTY, qw< ::Config ::Transformer ::Transformation> ) {
    Devel::EnforceEncapsulation->apply_to('Perl::Mogrify'.$pkg);
}

#-----------------------------------------------------------------------------
# Run mogrify against all of our own files

my $rcfile = File::Spec->catfile( 'xt', 'author', '40_perlmogrifyrc-code' );
Test::Perl::Mogrify->import( -profile => $rcfile );

all_mogrify_ok( starting_points_including_examples() );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
