#!perl

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Perl::Mogrify::UserProfile;
use Perl::Mogrify::TransformerFactory (-test => 1);
use Perl::Mogrify::TransformerListing;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

my $profile = Perl::Mogrify::UserProfile->new( -profile => 'NONE' );
my @policy_names = Perl::Mogrify::TransformerFactory::site_policy_names();
my $factory = Perl::Mogrify::TransformerFactory->new( -profile => $profile );
my @transformers = map { $factory->create_policy( -name => $_ ) } @policy_names;
my $listing = Perl::Mogrify::TransformerListing->new( -transformers => \@transformers );
my $policy_count = scalar @transformers;

plan( tests => $policy_count + 1);

#-----------------------------------------------------------------------------
# These tests verify that the listing has the right number of lines (one per
# policy) and that each line matches the expected pattern.  This indirectly
# verifies that each core policy declares at least one theme.

my $listing_as_string = "$listing";
my @listing_lines = split m/ \n /xms, $listing_as_string;
my $line_count = scalar @listing_lines;
is( $line_count, $policy_count, qq{Listing has all $policy_count transformers} );


my $listing_pattern = qr< \A \d [ ] [\w:]+ [ ] \[ [\w\s]+ \] \z >xms;
for my $line ( @listing_lines ) {
    like($line, $listing_pattern, 'Listing format matches expected pattern');
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/12_policylisting.t_without_optional_dependencies.t
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