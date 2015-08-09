#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::UserProfile;
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::TestUtils qw();

use Test::More tests => 10;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------

{
    my $transformer_name = 'Perl::ToPerl6::Transformer::Packages::FormatPackageUsages';
    my $params = {severity => 2, set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::ToPerl6::TransformerFactory->new( -profile  => $userprof );


    # Now test...
    my $transformer = $pf->create_transformer( -name => $transformer_name, -params => $params );
    is( ref $transformer, $transformer_name, 'Created correct type of transformer');

    my $severity = $transformer->get_severity();
    is( $severity, 2, 'Set the severity');

    my @themes = $transformer->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Using short module name.
{
    my $transformer_name = 'Variables::ReplaceUndef';
    my $params = {set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::ToPerl6::TransformerFactory->new( -profile  => $userprof );


    # Now test...
    my $transformer = $pf->create_transformer( -name => $transformer_name, -params => $params );
    my $transformer_name_long = 'Perl::ToPerl6::Transformer::' . $transformer_name;
    is( ref $transformer, $transformer_name_long, 'Created correct type of transformer');

    my @themes = $transformer->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $userprof = Perl::ToPerl6::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::ToPerl6::TransformerFactory->new( -profile  => $userprof );

    # Try missing arguments
    eval{ $pf->create_transformer() };
    like(
        $EVAL_ERROR,
        qr/The [ ] -name [ ] argument/xms,
        'create without -name arg',
    );

    # Try creating bogus transformer
    eval{ $pf->create_transformer( -name => 'Perl::ToPerl6::Foo' ) };
    like(
        $EVAL_ERROR,
        qr/Can't [ ] locate [ ] object [ ] method/xms,
        'create bogus transformer',
    );

    # Try using a bogus severity level
    my $transformer_name = 'Packages::FormatPackageUsages';
    my $transformer_params = {severity => 'bogus'};
    eval{ $pf->create_transformer( -name => $transformer_name, -params => $transformer_params)};
    like(
        $EVAL_ERROR,
        qr/Invalid [ ] severity: [ ] "bogus"/xms,
        'create transformer w/ bogus severity',
    );
}

#-----------------------------------------------------------------------------
# Test warnings about bogus transformers

{
    my $last_warning = q{}; #Trap warning messages here
    local $SIG{__WARN__} = sub { $last_warning = shift };

    my $profile = { 'Perl::ToPerl6::Bogus' => {} };
    my $userprof = Perl::ToPerl6::UserProfile->new( -profile => $profile );
    my $pf = Perl::ToPerl6::TransformerFactory->new( -profile  => $userprof );
    like(
        $last_warning,
        qr/^Transformer [ ] ".*Bogus" [ ] is [ ] not [ ] installed/xms,
        'Got expected warning for positive configuration of Transformer.',
    );
    $last_warning = q{};

    $profile = { '-Perl::ToPerl6::Shizzle' => {} };
    $userprof = Perl::ToPerl6::UserProfile->new( -profile => $profile );
    $pf = Perl::ToPerl6::TransformerFactory->new( -profile  => $userprof );
    like(
        $last_warning,
        qr/^Transformer [ ] ".*Shizzle" [ ] is [ ] not [ ] installed/xms,
        'Got expected warning for negative configuration of Transformer.',
    );
    $last_warning = q{};
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/11_transformerfactory.t_without_optional_dependencies.t
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
