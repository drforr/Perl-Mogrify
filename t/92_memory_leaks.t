#!perl

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

use PPI::Document;

use Perl::ToPerl6::TransformerFactory -test => 1;
use Perl::ToPerl6::Document;
use Perl::ToPerl6;
use Perl::ToPerl6::TestUtils qw();

use Test::More; #plan set below

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

eval 'use Test::Memory::Cycle; 1'
    or plan skip_all => 'Test::Memory::Cycle requried to test memory leaks';

#-----------------------------------------------------------------------------
{

    # We have to create and test Perl::ToPerl6::Document for memory leaks
    # separately because it is not a persistent attribute of the Perl::ToPerl6
    # object.  The current API requires us to create the P::C::Document from
    # an instance of an existing PPI::Document.  In the future, I hope to make
    # that interface a little more opaque.  But this works for now.

    # Coincidentally, I've discovered that PPI::Documents may or may not
    # contain circular references, depending on the input code.  On some
    # level, I'm sure this makes perfect sense, but I haven't stopped to think
    # about it.  The particular input we use here does not seem to create
    # circular references.

    my $code    = q<print foo(); split /this/, $that;>; ## no mogrify (RequireInterpolationOfMetachars)
    my $ppi_doc = PPI::Document->new( \$code );
    my $pc_doc  = Perl::ToPerl6::Document->new( '-source' => $ppi_doc );
    my $mogrify  = Perl::ToPerl6->new( -severity => 1 );
    my @transformations = $mogrify->transform( $pc_doc );
    confess 'No transformations were created' if not @transformations;

    # One test for each transformation, plus one each for ToPerl6 and Document.
    plan( tests => scalar @transformations + 2 );

    memory_cycle_ok( $pc_doc );
    memory_cycle_ok( $mogrify );
    foreach my $transformation (@transformations) {
        memory_cycle_ok($_);
    }
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/92_memory_leaks.t.without_optional_dependencies.t
1;

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
