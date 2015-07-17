#!perl

# Simple self-compliance tests for .run files.

use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec qw<>;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_MOGRIFY_CACHE} ) {
    require PPI::Cache;
    my $cache_path =
        File::Spec->catdir(
            File::Spec->tmpdir(),
            "test-perl-mogrify-cache-$ENV{USER}"
        );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Run mogrify against all of our own files

my $rcfile = File::Spec->catfile( qw< xt author 43_perlmogrifyrc-run-files > );
Test::Perl::Mogrify->import( -profile => $rcfile );

{
    # About to commit evil, but it's against ourselves.
    no warnings qw< redefine >;
    local *Perl::Mogrify::Utils::_is_perl = sub { 1 };

    all_mogrify_ok( glob 't/*/*.run' );
}

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
