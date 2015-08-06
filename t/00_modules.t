#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use PPI::Document;

use Perl::ToPerl6::TestUtils qw(bundled_policy_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

my @bundled_policy_names = bundled_policy_names();

my @concrete_exceptions = qw{
    AggregateConfiguration
    Configuration::Generic
    Configuration::NonExistentTransformer
    Configuration::Option::Global::ExtraParameter
    Configuration::Option::Global::ParameterValue
    Configuration::Option::Transformer::ExtraParameter
    Configuration::Option::Transformer::ParameterValue
    Fatal::Generic
    Fatal::Internal
    Fatal::TransformerDefinition
    IO
};

plan tests =>
        144
    +   (  9 * scalar @concrete_exceptions  )
    +   ( 17 * scalar @bundled_policy_names )
;

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6 module interface

use_ok('Perl::ToPerl6') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6', 'new');
can_ok('Perl::ToPerl6', 'apply_transform');
can_ok('Perl::ToPerl6', 'config');
can_ok('Perl::ToPerl6', 'transform');
can_ok('Perl::ToPerl6', 'transformers');

#Set -profile to avoid messing with .perlmogrifyrc
my $mogrify = Perl::ToPerl6->new( -profile => 'NONE' );
isa_ok($mogrify, 'Perl::ToPerl6');
is($mogrify->VERSION(), $version_string, 'Perl::ToPerl6 version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Config module interface

use_ok('Perl::ToPerl6::Config') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::Config', 'new');
can_ok('Perl::ToPerl6::Config', 'apply_transform');
can_ok('Perl::ToPerl6::Config', 'transformers');
can_ok('Perl::ToPerl6::Config', 'exclude');
can_ok('Perl::ToPerl6::Config', 'force');
can_ok('Perl::ToPerl6::Config', 'include');
can_ok('Perl::ToPerl6::Config', 'only');
can_ok('Perl::ToPerl6::Config', 'profile_strictness');
can_ok('Perl::ToPerl6::Config', 'severity');
can_ok('Perl::ToPerl6::Config', 'single_policy');
can_ok('Perl::ToPerl6::Config', 'theme');
can_ok('Perl::ToPerl6::Config', 'top');
can_ok('Perl::ToPerl6::Config', 'verbose');
can_ok('Perl::ToPerl6::Config', 'color');
can_ok('Perl::ToPerl6::Config', 'unsafe_allowed');
can_ok('Perl::ToPerl6::Config', 'mogrification_fatal');
can_ok('Perl::ToPerl6::Config', 'site_policy_names');
can_ok('Perl::ToPerl6::Config', 'color_severity_highest');
can_ok('Perl::ToPerl6::Config', 'color_severity_high');
can_ok('Perl::ToPerl6::Config', 'color_severity_medium');
can_ok('Perl::ToPerl6::Config', 'color_severity_low');
can_ok('Perl::ToPerl6::Config', 'color_severity_lowest');
can_ok('Perl::ToPerl6::Config', 'program_extensions');
can_ok('Perl::ToPerl6::Config', 'program_extensions_as_regexes');

#Set -profile to avoid messing with .perlmogrifyrc
my $config = Perl::ToPerl6::Config->new( -profile => 'NONE');
isa_ok($config, 'Perl::ToPerl6::Config');
is($config->VERSION(), $version_string, 'Perl::ToPerl6::Config version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Config::OptionsProcessor module interface

use_ok('Perl::ToPerl6::OptionsProcessor') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::OptionsProcessor', 'new');
can_ok('Perl::ToPerl6::OptionsProcessor', 'exclude');
can_ok('Perl::ToPerl6::OptionsProcessor', 'include');
can_ok('Perl::ToPerl6::OptionsProcessor', 'force');
can_ok('Perl::ToPerl6::OptionsProcessor', 'only');
can_ok('Perl::ToPerl6::OptionsProcessor', 'profile_strictness');
can_ok('Perl::ToPerl6::OptionsProcessor', 'single_policy');
can_ok('Perl::ToPerl6::OptionsProcessor', 'severity');
can_ok('Perl::ToPerl6::OptionsProcessor', 'theme');
can_ok('Perl::ToPerl6::OptionsProcessor', 'top');
can_ok('Perl::ToPerl6::OptionsProcessor', 'verbose');
can_ok('Perl::ToPerl6::OptionsProcessor', 'color');
can_ok('Perl::ToPerl6::OptionsProcessor', 'allow_unsafe');
can_ok('Perl::ToPerl6::OptionsProcessor', 'mogrification_fatal');
can_ok('Perl::ToPerl6::OptionsProcessor', 'color_severity_highest');
can_ok('Perl::ToPerl6::OptionsProcessor', 'color_severity_high');
can_ok('Perl::ToPerl6::OptionsProcessor', 'color_severity_medium');
can_ok('Perl::ToPerl6::OptionsProcessor', 'color_severity_low');
can_ok('Perl::ToPerl6::OptionsProcessor', 'color_severity_lowest');
can_ok('Perl::ToPerl6::OptionsProcessor', 'program_extensions');

my $processor = Perl::ToPerl6::OptionsProcessor->new();
isa_ok($processor, 'Perl::ToPerl6::OptionsProcessor');
is($processor->VERSION(), $version_string, 'Perl::ToPerl6::OptionsProcessor version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Transformer module interface

use_ok('Perl::ToPerl6::Transformer') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::Transformer', 'add_themes');
can_ok('Perl::ToPerl6::Transformer', 'applies_to');
can_ok('Perl::ToPerl6::Transformer', 'default_maximum_transformations_per_document');
can_ok('Perl::ToPerl6::Transformer', 'default_severity');
can_ok('Perl::ToPerl6::Transformer', 'default_themes');
can_ok('Perl::ToPerl6::Transformer', 'get_abstract');
can_ok('Perl::ToPerl6::Transformer', 'get_format');
can_ok('Perl::ToPerl6::Transformer', 'get_long_name');
can_ok('Perl::ToPerl6::Transformer', 'get_maximum_transformations_per_document');
can_ok('Perl::ToPerl6::Transformer', 'get_parameters');
can_ok('Perl::ToPerl6::Transformer', 'get_raw_abstract');
can_ok('Perl::ToPerl6::Transformer', 'get_severity');
can_ok('Perl::ToPerl6::Transformer', 'get_short_name');
can_ok('Perl::ToPerl6::Transformer', 'get_themes');
can_ok('Perl::ToPerl6::Transformer', 'initialize_if_enabled');
can_ok('Perl::ToPerl6::Transformer', 'is_enabled');
can_ok('Perl::ToPerl6::Transformer', 'is_safe');
can_ok('Perl::ToPerl6::Transformer', 'new');
can_ok('Perl::ToPerl6::Transformer', 'new_parameter_value_exception');
can_ok('Perl::ToPerl6::Transformer', 'parameter_metadata_available');
can_ok('Perl::ToPerl6::Transformer', 'prepare_to_scan_document');
can_ok('Perl::ToPerl6::Transformer', 'set_format');
can_ok('Perl::ToPerl6::Transformer', 'set_maximum_transformations_per_document');
can_ok('Perl::ToPerl6::Transformer', 'set_severity');
can_ok('Perl::ToPerl6::Transformer', 'set_themes');
can_ok('Perl::ToPerl6::Transformer', 'throw_parameter_value_exception');
can_ok('Perl::ToPerl6::Transformer', 'to_string');
can_ok('Perl::ToPerl6::Transformer', 'transform');
can_ok('Perl::ToPerl6::Transformer', 'transformation');
can_ok('Perl::ToPerl6::Transformer', 'is_safe');

{
    my $policy = Perl::ToPerl6::Transformer->new();
    isa_ok($policy, 'Perl::ToPerl6::Transformer');
    is($policy->VERSION(), $version_string, 'Perl::ToPerl6::Transformer version');
}

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Transformation module interface

use_ok('Perl::ToPerl6::Transformation') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::Transformation', 'description');
can_ok('Perl::ToPerl6::Transformation', 'diagnostics');
can_ok('Perl::ToPerl6::Transformation', 'explanation');
can_ok('Perl::ToPerl6::Transformation', 'get_format');
can_ok('Perl::ToPerl6::Transformation', 'location');
can_ok('Perl::ToPerl6::Transformation', 'new');
can_ok('Perl::ToPerl6::Transformation', 'policy');
can_ok('Perl::ToPerl6::Transformation', 'set_format');
can_ok('Perl::ToPerl6::Transformation', 'severity');
can_ok('Perl::ToPerl6::Transformation', 'sort_by_location');
can_ok('Perl::ToPerl6::Transformation', 'sort_by_severity');
can_ok('Perl::ToPerl6::Transformation', 'source');
can_ok('Perl::ToPerl6::Transformation', 'to_string');

my $code = q{print 'Hello World';};
my $doc = PPI::Document->new(\$code);
my $viol = Perl::ToPerl6::Transformation->new(undef, undef, $doc, undef);
isa_ok($viol, 'Perl::ToPerl6::Transformation');
is($viol->VERSION(), $version_string, 'Perl::ToPerl6::Transformation version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::UserProfile module interface

use_ok('Perl::ToPerl6::UserProfile') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::UserProfile', 'options_processor');
can_ok('Perl::ToPerl6::UserProfile', 'new');
can_ok('Perl::ToPerl6::UserProfile', 'policy_is_disabled');
can_ok('Perl::ToPerl6::UserProfile', 'policy_is_enabled');

my $up = Perl::ToPerl6::UserProfile->new();
isa_ok($up, 'Perl::ToPerl6::UserProfile');
is($up->VERSION(), $version_string, 'Perl::ToPerl6::UserProfile version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::TransformerFactory module interface

use_ok('Perl::ToPerl6::TransformerFactory') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::TransformerFactory', 'create_policy');
can_ok('Perl::ToPerl6::TransformerFactory', 'new');
can_ok('Perl::ToPerl6::TransformerFactory', 'site_policy_names');


my $profile = Perl::ToPerl6::UserProfile->new();
my $factory = Perl::ToPerl6::TransformerFactory->new( -profile => $profile );
isa_ok($factory, 'Perl::ToPerl6::TransformerFactory');
is($factory->VERSION(), $version_string, 'Perl::ToPerl6::TransformerFactory version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Theme module interface

use_ok('Perl::ToPerl6::Theme') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::Theme', 'new');
can_ok('Perl::ToPerl6::Theme', 'rule');
can_ok('Perl::ToPerl6::Theme', 'policy_is_thematic');


my $theme = Perl::ToPerl6::Theme->new( -rule => 'foo' );
isa_ok($theme, 'Perl::ToPerl6::Theme');
is($theme->VERSION(), $version_string, 'Perl::ToPerl6::Theme version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::TransformerListing module interface

use_ok('Perl::ToPerl6::TransformerListing') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::TransformerListing', 'new');
can_ok('Perl::ToPerl6::TransformerListing', 'to_string');

my $listing = Perl::ToPerl6::TransformerListing->new();
isa_ok($listing, 'Perl::ToPerl6::TransformerListing');
is($listing->VERSION(), $version_string, 'Perl::ToPerl6::TransformerListing version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::ProfilePrototype module interface

use_ok('Perl::ToPerl6::ProfilePrototype') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::ProfilePrototype', 'new');
can_ok('Perl::ToPerl6::ProfilePrototype', 'to_string');

my $prototype = Perl::ToPerl6::ProfilePrototype->new();
isa_ok($prototype, 'Perl::ToPerl6::ProfilePrototype');
is($prototype->VERSION(), $version_string, 'Perl::ToPerl6::ProfilePrototype version');

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Command module interface

use_ok('Perl::ToPerl6::Command') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::ToPerl6::Command', 'run');

#-----------------------------------------------------------------------------
# Test module interface for exceptions

{
    foreach my $class (
        map { "Perl::ToPerl6::Exception::$_" } @concrete_exceptions
    ) {
        use_ok($class) or BAIL_OUT(q<Can't continue.>);
        can_ok($class, 'new');
        can_ok($class, 'throw');
        can_ok($class, 'message');
        can_ok($class, 'error');
        can_ok($class, 'full_message');
        can_ok($class, 'as_string');

        my $exception = $class->new();
        isa_ok($exception, $class);
        is($exception->VERSION(), $version_string, "$class version");
    }
}

#-----------------------------------------------------------------------------
# Test module interface for each Transformer subclass

{
    for my $mod ( @bundled_policy_names ) {

        use_ok($mod) or BAIL_OUT(q<Can't continue.>);
        can_ok($mod, 'applies_to');
        can_ok($mod, 'default_severity');
        can_ok($mod, 'default_themes');
        can_ok($mod, 'get_severity');
        can_ok($mod, 'get_themes');
        can_ok($mod, 'is_enabled');
        can_ok($mod, 'new');
        can_ok($mod, 'set_severity');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'transform');
        can_ok($mod, 'transformation');
        can_ok($mod, 'is_safe');

        my $policy = $mod->new();
        isa_ok($policy, 'Perl::ToPerl6::Transformer');
        is($policy->VERSION(), $version_string, "Version of $mod");
        ok($policy->is_safe(), "CORE policy $mod is marked safe");
    }
}

#-----------------------------------------------------------------------------
# Test functional interface to Perl::ToPerl6

Perl::ToPerl6->import( qw(transform) );
can_ok('main', 'transform');  #Export test

# TODO: These tests are weak. They just verify that it doesn't
# blow up, and that at least one transformation is returned.
ok( transform( \$code ), 'Functional style, no config' );
ok( transform( {}, \$code ), 'Functional style, empty config' );
ok( transform( {severity => 1}, \$code ), 'Functional style, with config');
ok( !transform(), 'Functional style, no args at all');
ok( !transform(undef, undef), 'Functional style, undef args');

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/00_modules.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
