#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use PPI::Document;

use Perl::Mogrify::TestUtils qw(bundled_policy_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Perl::Mogrify::TestUtils::block_perlmogrifyrc();

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
    +   ( 17 * scalar @bundled_policy_names );

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test Perl::Mogrify module interface

use_ok('Perl::Mogrify') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify', 'new');
can_ok('Perl::Mogrify', 'add_policy');
can_ok('Perl::Mogrify', 'config');
can_ok('Perl::Mogrify', 'critique');
can_ok('Perl::Mogrify', 'policies');

#Set -profile to avoid messing with .perlmogrifyrc
my $mogrify = Perl::Mogrify->new( -profile => 'NONE' );
isa_ok($mogrify, 'Perl::Mogrify');
is($mogrify->VERSION(), $version_string, 'Perl::Mogrify version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::Config module interface

use_ok('Perl::Mogrify::Config') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::Config', 'new');
can_ok('Perl::Mogrify::Config', 'add_policy');
can_ok('Perl::Mogrify::Config', 'policies');
can_ok('Perl::Mogrify::Config', 'exclude');
can_ok('Perl::Mogrify::Config', 'force');
can_ok('Perl::Mogrify::Config', 'include');
can_ok('Perl::Mogrify::Config', 'only');
can_ok('Perl::Mogrify::Config', 'profile_strictness');
can_ok('Perl::Mogrify::Config', 'severity');
can_ok('Perl::Mogrify::Config', 'single_policy');
can_ok('Perl::Mogrify::Config', 'theme');
can_ok('Perl::Mogrify::Config', 'top');
can_ok('Perl::Mogrify::Config', 'verbose');
can_ok('Perl::Mogrify::Config', 'color');
can_ok('Perl::Mogrify::Config', 'unsafe_allowed');
can_ok('Perl::Mogrify::Config', 'mogrification_fatal');
can_ok('Perl::Mogrify::Config', 'site_policy_names');
can_ok('Perl::Mogrify::Config', 'color_severity_highest');
can_ok('Perl::Mogrify::Config', 'color_severity_high');
can_ok('Perl::Mogrify::Config', 'color_severity_medium');
can_ok('Perl::Mogrify::Config', 'color_severity_low');
can_ok('Perl::Mogrify::Config', 'color_severity_lowest');
can_ok('Perl::Mogrify::Config', 'program_extensions');
can_ok('Perl::Mogrify::Config', 'program_extensions_as_regexes');

#Set -profile to avoid messing with .perlmogrifyrc
my $config = Perl::Mogrify::Config->new( -profile => 'NONE');
isa_ok($config, 'Perl::Mogrify::Config');
is($config->VERSION(), $version_string, 'Perl::Mogrify::Config version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::Config::OptionsProcessor module interface

use_ok('Perl::Mogrify::OptionsProcessor') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::OptionsProcessor', 'new');
can_ok('Perl::Mogrify::OptionsProcessor', 'exclude');
can_ok('Perl::Mogrify::OptionsProcessor', 'include');
can_ok('Perl::Mogrify::OptionsProcessor', 'force');
can_ok('Perl::Mogrify::OptionsProcessor', 'only');
can_ok('Perl::Mogrify::OptionsProcessor', 'profile_strictness');
can_ok('Perl::Mogrify::OptionsProcessor', 'single_policy');
can_ok('Perl::Mogrify::OptionsProcessor', 'severity');
can_ok('Perl::Mogrify::OptionsProcessor', 'theme');
can_ok('Perl::Mogrify::OptionsProcessor', 'top');
can_ok('Perl::Mogrify::OptionsProcessor', 'verbose');
can_ok('Perl::Mogrify::OptionsProcessor', 'color');
can_ok('Perl::Mogrify::OptionsProcessor', 'allow_unsafe');
can_ok('Perl::Mogrify::OptionsProcessor', 'mogrification_fatal');
can_ok('Perl::Mogrify::OptionsProcessor', 'color_severity_highest');
can_ok('Perl::Mogrify::OptionsProcessor', 'color_severity_high');
can_ok('Perl::Mogrify::OptionsProcessor', 'color_severity_medium');
can_ok('Perl::Mogrify::OptionsProcessor', 'color_severity_low');
can_ok('Perl::Mogrify::OptionsProcessor', 'color_severity_lowest');
can_ok('Perl::Mogrify::OptionsProcessor', 'program_extensions');

my $processor = Perl::Mogrify::OptionsProcessor->new();
isa_ok($processor, 'Perl::Mogrify::OptionsProcessor');
is($processor->VERSION(), $version_string, 'Perl::Mogrify::OptionsProcessor version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::Transformer module interface

use_ok('Perl::Mogrify::Transformer') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::Transformer', 'add_themes');
can_ok('Perl::Mogrify::Transformer', 'applies_to');
can_ok('Perl::Mogrify::Transformer', 'default_maximum_violations_per_document');
can_ok('Perl::Mogrify::Transformer', 'default_severity');
can_ok('Perl::Mogrify::Transformer', 'default_themes');
can_ok('Perl::Mogrify::Transformer', 'get_abstract');
can_ok('Perl::Mogrify::Transformer', 'get_format');
can_ok('Perl::Mogrify::Transformer', 'get_long_name');
can_ok('Perl::Mogrify::Transformer', 'get_maximum_violations_per_document');
can_ok('Perl::Mogrify::Transformer', 'get_parameters');
can_ok('Perl::Mogrify::Transformer', 'get_raw_abstract');
can_ok('Perl::Mogrify::Transformer', 'get_severity');
can_ok('Perl::Mogrify::Transformer', 'get_short_name');
can_ok('Perl::Mogrify::Transformer', 'get_themes');
can_ok('Perl::Mogrify::Transformer', 'initialize_if_enabled');
can_ok('Perl::Mogrify::Transformer', 'is_enabled');
can_ok('Perl::Mogrify::Transformer', 'is_safe');
can_ok('Perl::Mogrify::Transformer', 'new');
can_ok('Perl::Mogrify::Transformer', 'new_parameter_value_exception');
can_ok('Perl::Mogrify::Transformer', 'parameter_metadata_available');
can_ok('Perl::Mogrify::Transformer', 'prepare_to_scan_document');
can_ok('Perl::Mogrify::Transformer', 'set_format');
can_ok('Perl::Mogrify::Transformer', 'set_maximum_violations_per_document');
can_ok('Perl::Mogrify::Transformer', 'set_severity');
can_ok('Perl::Mogrify::Transformer', 'set_themes');
can_ok('Perl::Mogrify::Transformer', 'throw_parameter_value_exception');
can_ok('Perl::Mogrify::Transformer', 'to_string');
can_ok('Perl::Mogrify::Transformer', 'transform');
can_ok('Perl::Mogrify::Transformer', 'violation');
can_ok('Perl::Mogrify::Transformer', 'is_safe');

{
    my $policy = Perl::Mogrify::Transformer->new();
    isa_ok($policy, 'Perl::Mogrify::Transformer');
    is($policy->VERSION(), $version_string, 'Perl::Mogrify::Transformer version');
}

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::Violation module interface

use_ok('Perl::Mogrify::Violation') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::Violation', 'description');
can_ok('Perl::Mogrify::Violation', 'diagnostics');
can_ok('Perl::Mogrify::Violation', 'explanation');
can_ok('Perl::Mogrify::Violation', 'get_format');
can_ok('Perl::Mogrify::Violation', 'location');
can_ok('Perl::Mogrify::Violation', 'new');
can_ok('Perl::Mogrify::Violation', 'policy');
can_ok('Perl::Mogrify::Violation', 'set_format');
can_ok('Perl::Mogrify::Violation', 'severity');
can_ok('Perl::Mogrify::Violation', 'sort_by_location');
can_ok('Perl::Mogrify::Violation', 'sort_by_severity');
can_ok('Perl::Mogrify::Violation', 'source');
can_ok('Perl::Mogrify::Violation', 'to_string');

my $code = q{print 'Hello World';};
my $doc = PPI::Document->new(\$code);
my $viol = Perl::Mogrify::Violation->new(undef, undef, $doc, undef);
isa_ok($viol, 'Perl::Mogrify::Violation');
is($viol->VERSION(), $version_string, 'Perl::Mogrify::Violation version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::UserProfile module interface

use_ok('Perl::Mogrify::UserProfile') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::UserProfile', 'options_processor');
can_ok('Perl::Mogrify::UserProfile', 'new');
can_ok('Perl::Mogrify::UserProfile', 'policy_is_disabled');
can_ok('Perl::Mogrify::UserProfile', 'policy_is_enabled');

my $up = Perl::Mogrify::UserProfile->new();
isa_ok($up, 'Perl::Mogrify::UserProfile');
is($up->VERSION(), $version_string, 'Perl::Mogrify::UserProfile version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::TransformerFactory module interface

use_ok('Perl::Mogrify::TransformerFactory') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::TransformerFactory', 'create_policy');
can_ok('Perl::Mogrify::TransformerFactory', 'new');
can_ok('Perl::Mogrify::TransformerFactory', 'site_policy_names');


my $profile = Perl::Mogrify::UserProfile->new();
my $factory = Perl::Mogrify::TransformerFactory->new( -profile => $profile );
isa_ok($factory, 'Perl::Mogrify::TransformerFactory');
is($factory->VERSION(), $version_string, 'Perl::Mogrify::TransformerFactory version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::Theme module interface

use_ok('Perl::Mogrify::Theme') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::Theme', 'new');
can_ok('Perl::Mogrify::Theme', 'rule');
can_ok('Perl::Mogrify::Theme', 'policy_is_thematic');


my $theme = Perl::Mogrify::Theme->new( -rule => 'foo' );
isa_ok($theme, 'Perl::Mogrify::Theme');
is($theme->VERSION(), $version_string, 'Perl::Mogrify::Theme version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::TransformerListing module interface

use_ok('Perl::Mogrify::TransformerListing') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::TransformerListing', 'new');
can_ok('Perl::Mogrify::TransformerListing', 'to_string');

my $listing = Perl::Mogrify::TransformerListing->new();
isa_ok($listing, 'Perl::Mogrify::TransformerListing');
is($listing->VERSION(), $version_string, 'Perl::Mogrify::TransformerListing version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::ProfilePrototype module interface

use_ok('Perl::Mogrify::ProfilePrototype') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::ProfilePrototype', 'new');
can_ok('Perl::Mogrify::ProfilePrototype', 'to_string');

my $prototype = Perl::Mogrify::ProfilePrototype->new();
isa_ok($prototype, 'Perl::Mogrify::ProfilePrototype');
is($prototype->VERSION(), $version_string, 'Perl::Mogrify::ProfilePrototype version');

#-----------------------------------------------------------------------------
# Test Perl::Mogrify::Command module interface

use_ok('Perl::Mogrify::Command') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Mogrify::Command', 'run');

#-----------------------------------------------------------------------------
# Test module interface for exceptions

{
    foreach my $class (
        map { "Perl::Mogrify::Exception::$_" } @concrete_exceptions
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
        can_ok($mod, 'violation');
        can_ok($mod, 'is_safe');

        my $policy = $mod->new();
        isa_ok($policy, 'Perl::Mogrify::Transformer');
        is($policy->VERSION(), $version_string, "Version of $mod");
        ok($policy->is_safe(), "CORE policy $mod is marked safe");
    }
}

#-----------------------------------------------------------------------------
# Test functional interface to Perl::Mogrify

Perl::Mogrify->import( qw(critique) );
can_ok('main', 'critique');  #Export test

# TODO: These tests are weak. They just verify that it doesn't
# blow up, and that at least one violation is returned.
ok( critique( \$code ), 'Functional style, no config' );
ok( critique( {}, \$code ), 'Functional style, empty config' );
ok( critique( {severity => 1}, \$code ), 'Functional style, with config');
ok( !critique(), 'Functional style, no args at all');
ok( !critique(undef, undef), 'Functional style, undef args');

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
