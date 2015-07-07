#!perl

use 5.006001;
use strict;
use warnings;

use Perl::Mogrify::UserProfile;
use Perl::Mogrify::TransformerFactory (-test => 1);
use Perl::Mogrify::TestUtils qw(bundled_policy_names);

use Test::More tests => 1;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Perl::Mogrify::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------

my $profile = Perl::Mogrify::UserProfile->new();
my $factory = Perl::Mogrify::TransformerFactory->new( -profile => $profile );
my @found_transformers = sort map { ref } $factory->create_all_transformers();
my $test_label = 'successfully loaded transformers matches MANIFEST';
is_deeply( \@found_transformers, [bundled_policy_names()], $test_label );

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/13_bundled_transformers.t_without_optional_dependencies.t
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
