#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::UserProfile qw();
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::TransformerParameter qw{ $NO_DESCRIPTION_AVAILABLE };
use Perl::ToPerl6::Utils qw( policy_short_name );
use Perl::ToPerl6::TestUtils qw(bundled_policy_names);

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

use Test::More; #plan set below!

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------
# This program proves that each policy that ships with Perl::ToPerl6 overrides
# the supported_parameters() method and, assuming that the policy is
# configurable, that each parameter can parse its own default_string.
#
# This program also verifies that Perl::ToPerl6::TransformerFactory throws an
# exception when we try to create a policy with bogus parameters.  However, it
# is your responsibility to verify that valid parameters actually work as
# expected.  You can do this by using the #parms directive in the *.run files.
#-----------------------------------------------------------------------------

# Figure out how many tests there will be...
my @all_transformers = bundled_policy_names();
my @all_params   = map { $_->supported_parameters() } @all_transformers;
my $ntests       = @all_transformers + 2 * @all_params;
plan( tests => $ntests );

#-----------------------------------------------------------------------------

for my $policy ( @all_transformers ) {
    test_has_declared_parameters( $policy );
    test_invalid_parameters( $policy );
    test_supported_parameters( $policy );
}

#-----------------------------------------------------------------------------

sub test_supported_parameters {
    my $policy_name = shift;
    my @supported_params = $policy_name->supported_parameters();
    my $config = Perl::ToPerl6::Config->new( -profile => 'NONE' );

    for my $param_specification ( @supported_params ) {
        my $parameter =
            Perl::ToPerl6::TransformerParameter->new($param_specification);
        my $param_name = $parameter->get_name();
        my $description = $parameter->get_description();

        ok(
            $description && $description ne $NO_DESCRIPTION_AVAILABLE,
            qq{Param "$param_name" for policy "$policy_name" has a description},
        );

        my %args = (
            -policy => $policy_name,
            -params => {
                 $param_name => $parameter->get_default_string(),
            }
        );
        eval { $config->apply_transform( %args ) };
        is(
            $EVAL_ERROR,
            q{},
            qq{Created policy "$policy_name" with param "$param_name"},
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_invalid_parameters {
    my $policy = shift;
    my $bogus_params  = { bogus => 'shizzle' };
    my $profile = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
    my $factory = Perl::ToPerl6::TransformerFactory->new(
        -profile => $profile, '-profile-strictness' => 'fatal' );

    my $policy_name = policy_short_name($policy);
    my $label = qq{Created $policy_name with bogus parameters};

    eval { $factory->create_policy(-name => $policy, -params => $bogus_params) };
    like(
        $EVAL_ERROR,
        qr/The [ ] $policy_name [ ] policy [ ] doesn't [ ] take [ ] a [ ] "bogus" [ ] option/xms,
        $label
    );

    return;
}

#-----------------------------------------------------------------------------

sub test_has_declared_parameters {
    my $policy = shift;
    if ( not $policy->can('supported_parameters') ) {
        fail( qq{I don't know if $policy supports params} );
        diag( qq{This means $policy needs a supported_parameters() method} );
    }
    return;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/14_policy_parameters.t_without_optional_dependencies.t
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
