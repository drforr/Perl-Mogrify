#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::UserProfile qw();
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::TransformerParameter qw{ $NO_DESCRIPTION_AVAILABLE };
use Perl::ToPerl6::Utils qw( transformer_short_name );
use Perl::ToPerl6::TestUtils qw(bundled_transformer_names);

#-----------------------------------------------------------------------------

use Test::More; #plan set below!

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------
# This program proves that each transformer that ships with Perl::ToPerl6
# overrides the supported_parameters() method and, assuming that the
# transformer is configurable, that each parameter can parse its own
# default_string.
#
# This program also verifies that Perl::ToPerl6::TransformerFactory throws an
# exception when we try to create a transformer with bogus parameters.
# However, it is your responsibility to verify that valid parameters actually
# work as expected.  You can do this by using the #parms directive in the
# *.run files.
#-----------------------------------------------------------------------------

# Figure out how many tests there will be...
my @all_transformers = bundled_transformer_names();
my @all_params   = map { $_->supported_parameters() } @all_transformers;
my $ntests       = @all_transformers + 2 * @all_params;
plan( tests => $ntests );

#-----------------------------------------------------------------------------

for my $transformer ( @all_transformers ) {
    test_has_declared_parameters( $transformer );
    test_invalid_parameters( $transformer );
    test_supported_parameters( $transformer );
}

#-----------------------------------------------------------------------------

sub test_supported_parameters {
    my $transformer_name = shift;
    my @supported_params = $transformer_name->supported_parameters();
    my $config = Perl::ToPerl6::Config->new( -profile => 'NONE' );

    for my $param_specification ( @supported_params ) {
        my $parameter =
            Perl::ToPerl6::TransformerParameter->new($param_specification);
        my $param_name = $parameter->get_name();
        my $description = $parameter->get_description();

        ok(
            $description && $description ne $NO_DESCRIPTION_AVAILABLE,
            qq{Param "$param_name" for transformer "$transformer_name" has a description},
        );

        my %args = (
            -transformer => $transformer_name,
            -params => {
                 $param_name => $parameter->get_default_string(),
            }
        );
        eval { $config->apply_transform( %args ) };
        is(
            $EVAL_ERROR,
            q{},
            qq{Created transformer "$transformer_name" with param "$param_name"},
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_invalid_parameters {
    my $transformer = shift;
    my $bogus_params  = { bogus => 'shizzle' };
    my $profile = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
    my $factory = Perl::ToPerl6::TransformerFactory->new(
        -profile => $profile, '-profile-strictness' => 'fatal' );

    my $transformer_name = transformer_short_name($transformer);
    my $label = qq{Created $transformer_name with bogus parameters};

    eval { $factory->create_transformer(-name => $transformer, -params => $bogus_params) };
    like(
        $EVAL_ERROR,
        qr/The [ ] $transformer_name [ ] transformer [ ] doesn't [ ] take [ ] a [ ] "bogus" [ ] option/xms,
        $label
    );

    return;
}

#-----------------------------------------------------------------------------

sub test_has_declared_parameters {
    my $transformer = shift;
    if ( not $transformer->can('supported_parameters') ) {
        fail( qq{I don't know if $transformer supports params} );
        diag( qq{This means $transformer needs a supported_parameters() method} );
    }
    return;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/14_transformer_parameters.t_without_optional_dependencies.t
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
