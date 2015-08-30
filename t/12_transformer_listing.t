#!perl

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Perl::ToPerl6::UserProfile;
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::TransformerListing;

use Test::More;

#-----------------------------------------------------------------------------

my $profile = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
my @transformer_names = Perl::ToPerl6::TransformerFactory::site_transformer_names();
my $factory = Perl::ToPerl6::TransformerFactory->new( -profile => $profile );
my @transformers = map { $factory->create_transformer( -name => $_ ) } @transformer_names;
my $listing = Perl::ToPerl6::TransformerListing->new( -transformers => \@transformers );
my $transformer_count = scalar @transformers;

plan( tests => $transformer_count + 1);

#-----------------------------------------------------------------------------
# These tests verify that the listing has the right number of lines (one per
# transformer) and that each line matches the expected pattern.  This indirectly
# verifies that each core transformer declares at least one theme.

my $listing_as_string = "$listing";
my @listing_lines = split m/ \n /xms, $listing_as_string;
my $line_count = scalar @listing_lines;
is( $line_count, $transformer_count, qq{Listing has all $transformer_count transformers} );


my $listing_pattern = qr< \A \d [ ] [\w:]+ [ ] \[ [\w\s]+ \] \z >xms;
for my $line ( @listing_lines ) {
    like($line, $listing_pattern, 'Listing format matches expected pattern');
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/12_transformerlisting.t_without_optional_dependencies.t
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
