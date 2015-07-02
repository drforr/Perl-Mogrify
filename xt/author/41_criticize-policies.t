#!perl

# Extra self-compliance tests for Enforcer classes.  This just checks for
# additional POD sections that we want in every Enforcer module.  See the
# 41_perlcriticrc-policies file for the precise configuration.

use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec qw<>;

use Perl::Mogrify::PolicyFactory ( '-test' => 1 );

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

use Test::Perl::Mogrify;

#-----------------------------------------------------------------------------

# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require PPI::Cache;
    my $cache_path =
        File::Spec->catdir(
            File::Spec->tmpdir(),
            "test-perl-critic-cache-$ENV{USER}"
        );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Run critic against all of our own files

my $rcfile = File::Spec->catfile( qw< xt author 41_perlcriticrc-policies > );
Test::Perl::Mogrify->import( -profile => $rcfile );

my $path =
    File::Spec->catfile(
        -e 'blib' ? 'blib/lib' : 'lib',
        qw< Perl Mogrify Enforcer >,
    );
all_critic_ok( $path );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
