#!perl

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Perl::ToPerl6::UserProfile;
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::ThemeListing;

use Test::More tests => 1;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

my $profile = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
my @transformer_names = Perl::ToPerl6::TransformerFactory::site_transformer_names();
my $factory = Perl::ToPerl6::TransformerFactory->new( -profile => $profile );
my @transformers = map { $factory->create_transformer( -name => $_ ) } @transformer_names;
my $listing = Perl::ToPerl6::ThemeListing->new( -transformers => \@transformers );

my $expected = <<'END_EXPECTED';
bugs
certrec
certrule
complexity
core
cosmetic
maintenance
pbp
performance
portability
readability
security
tests
unicode
END_EXPECTED

my $listing_as_string = "$listing";
SKIP: {
  skip "XXX Need to restore this eventually", 1;
is( $listing_as_string, $expected, 'Theme list matched.' );
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/12_themelisting.t_without_optional_dependencies.t
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
