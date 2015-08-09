#!perl

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec;
use List::MoreUtils qw(all any);

use Perl::ToPerl6::Exception::AggregateConfiguration;
use Perl::ToPerl6::Config qw<>;
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::TestUtils qw<
    bundled_transformer_names
    names_of_transformers_willing_to_work
>;
use Perl::ToPerl6::Utils qw< :booleans :characters :severities >;
use Perl::ToPerl6::Utils::Constants qw< :color_severity >;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------

my @names_of_transformers_willing_to_work =
    names_of_transformers_willing_to_work(
        -severity   => $SEVERITY_LOWEST,
        -theme      => 'core',
    );
my @native_transformer_names  = bundled_transformer_names();
my $total_transformers   = scalar @names_of_transformers_willing_to_work;

#-----------------------------------------------------------------------------

{
    my $all_transformer_count =
        scalar
            Perl::ToPerl6::Config
                ->new(
                    -severity   => $SEVERITY_LOWEST,
                    -theme      => 'core',
                )
                ->all_transformers_enabled_or_not();

#    plan tests => 93 + $all_transformer_count - (129-88); # XXX Look into this later
plan tests => 88;
diag("XXX Fix the transformer count later");
}

#-----------------------------------------------------------------------------
# Test default config.  Increasing the severity should yield
# fewer and fewer transformers.  The exact number will fluctuate
# as we introduce new polices and/or change their severity.

SKIP: {
    skip "XXX For now all transformers are the same 'severity'", 4;
    my $last_transformer_count = $total_transformers + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my $configuration =
            Perl::ToPerl6::Config->new(
                -severity   => $severity,
                -theme      => 'core',
            );
        my $transformer_count = scalar $configuration->transformers();
        my $test_name = "Count native transformers, severity: $severity";
        cmp_ok($transformer_count, '<', $last_transformer_count, $test_name);
        $last_transformer_count = $transformer_count;
    }
}


#-----------------------------------------------------------------------------
# Same tests as above, but using a generated config

SKIP: {
    skip "XXX For now all transformers are the same 'severity'", 4;
    my %profile = map { $_ => {} } @native_transformer_names;
    my $last_transformer_count = $total_transformers + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my %pc_args = (
            -profile    => \%profile,
            -severity   => $severity,
            -theme      => 'core',
        );
        my $mogrify = Perl::ToPerl6::Config->new( %pc_args );
        my $transformer_count = scalar $mogrify->transformers();
        my $test_name = "Count all transformers, severity: $severity";
        cmp_ok($transformer_count, '<', $last_transformer_count, $test_name);
        $last_transformer_count = $transformer_count;
    }
}

#-----------------------------------------------------------------------------

SKIP: {
    skip "XXX For now all transformers are the same 'severity'", 1;
    my $configuration =
        Perl::ToPerl6::Config->new(
            -severity   => $SEVERITY_LOWEST,
            -theme      => 'core',
        );
    my %transformers_by_name =
        map { $_->get_short_name() => $_ } $configuration->transformers();

    foreach my $transformer ( $configuration->all_transformers_enabled_or_not() ) {
        my $enabled = $transformer->is_enabled();
        if ( delete $transformers_by_name{ $transformer->get_short_name() } ) {
            ok(
                $enabled,
                $transformer->get_short_name() . ' is enabled.',
            );
        }
        else {
            ok(
                ! $enabled && defined $enabled,
                $transformer->get_short_name() . ' is not enabled.',
            );
        }
    }

}

#-----------------------------------------------------------------------------
# Test config w/ multiple severity levels.  In this profile, we
# define an arbitrary severity for each Transformer so that severity
# levels 5 through 2 each have 10 Transformers.  All remaining Transformers
# are in the 1st severity level.


SKIP: {
    skip "XXX For now all transformers are the same 'severity'", 1;
    my %profile = ();
    my $severity = $SEVERITY_HIGHEST;
    for my $index ( 0 .. $#names_of_transformers_willing_to_work ) {
        if ($index and $index % 10 == 0) {
            $severity--;
        }
        if ($severity < $SEVERITY_LOWEST) {
            $severity = $SEVERITY_LOWEST;
        }

        $profile{$names_of_transformers_willing_to_work[$index]} =
            {severity => $severity};
    }

    for my $severity ( reverse $SEVERITY_LOWEST+1 .. $SEVERITY_HIGHEST ) {
        my %pc_args = (
            -profile    => \%profile,
            -severity   => $severity,
            -theme      => 'core',
        );
        my $mogrify = Perl::ToPerl6::Config->new( %pc_args );
        my $transformer_count = scalar $mogrify->transformers();
        my $expected_count = ($SEVERITY_HIGHEST - $severity + 1) * 10;
        my $test_name = "user-defined severity level: $severity";
        is( $transformer_count, $expected_count, $test_name );
    }

    # All remaining transformers should be at the lowest severity
    my %pc_args = (-profile => \%profile, -severity => $SEVERITY_LOWEST);
    my $mogrify = Perl::ToPerl6::Config->new( %pc_args );
    my $transformer_count = scalar $mogrify->transformers();
    my $expected_count = $SEVERITY_HIGHEST * 10;
    my $test_name = 'user-defined severity, all remaining transformers';
    cmp_ok( $transformer_count, '>=', $expected_count, $test_name);
}

#-----------------------------------------------------------------------------
# Test config with defaults

{
    my $examples_dir = 'examples';
    my $profile = File::Spec->catfile( $examples_dir, 'perlmogrifyrc' );
    my $c = Perl::ToPerl6::Config->new( -profile => $profile );

    is_deeply([$c->exclude()], [ qw(Array Variables) ],
              'user default exclude from file' );

    is_deeply([$c->include()], [ qw(CodeLayout Modules) ],
              'user default include from file' );

    is($c->force(),    1,  'user default force from file'     );
    is($c->only(),     1,  'user default only from file'      );
    is($c->severity(), 3,  'user default severity from file'  );
    is($c->theme()->rule(),    'danger || risky && ! pbp',  'user default theme from file');
    is($c->top(),      50, 'user default top from file'       );
    is($c->verbose(),  5,  'user default verbose from file'   );

    is($c->color_severity_highest(), 'bold red underline',
                        'user default color-severity-highest from file');
    is($c->color_severity_high(), 'bold magenta',
                        'user default color-severity-high from file');
    is($c->color_severity_medium(), 'blue',
                        'user default color-severity-medium from file');
    is($c->color_severity_low(), $EMPTY,
                        'user default color-severity-low from file');
    is($c->color_severity_lowest(), $EMPTY,
                        'user default color-severity-lowest from file');

    is_deeply([$c->program_extensions], [],
        'user default program-extensions from file');
    is_deeply([$c->program_extensions_as_regexes],
        [qr< @{[ quotemeta '.PL' ]} \z >smx ],
        'user default program-extensions from file, as regexes');
}

#-----------------------------------------------------------------------------
#Test pattern matching


SKIP: {
    skip "XXX For now all transformers are the same 'severity'", 1;
    # In this test, we'll use a custom profile to deactivate some
    # transformers, and then use the -include option to re-activate them.  So
    # the net result is that we should still end up with the all the
    # transformers.

    my %profile = (
        '-BasicTypes::Strings::FormatShellStrings' => {},
        '-Variables::FormatHashKeys' => {},
    );

    my @include = qw(capital quoted);
    my %pc_args = (
        -profile    => \%profile,
        -severity   => 1,
        -include    => \@include,
        -theme      => 'core',
    );
    my @transformers = Perl::ToPerl6::Config->new( %pc_args )->transformers();
    is(scalar @transformers, $total_transformers, 'include pattern matching');
}

#-----------------------------------------------------------------------------

{
    # For this test, we'll load the default config, but deactivate some of
    # the transformers using the -exclude option.  Then we make sure that none
    # of the remaining transformers match the -exclude patterns.

    my @exclude = qw(quote mixed VALUES); #Some assorted pattterns
    my %pc_args = (
        -severity   => 1,
        -exclude    => \@exclude,
    );
    my @transformers = Perl::ToPerl6::Config->new( %pc_args )->transformers();
    my $matches = grep { my $pol = ref; grep { $pol !~ /$_/ixms} @exclude } @transformers;
    is(scalar @transformers, $matches, 'exclude pattern matching');
}

#-----------------------------------------------------------------------------

{
    # In this test, we set -include and -exclude patterns to both match
    # some of the same transformers.  The -exclude option should have
    # precendece.

    my @include = qw(builtinfunc); #Include BuiltinFunctions::*
    my @exclude = qw(block);       #Exclude RequireBlockGrep, RequireBlockMap
    my %pc_args = (
        -severity   => 1,
        -include    => \@include,
        -exclude    => \@exclude,
    );
    my @transformers = Perl::ToPerl6::Config->new( %pc_args )->transformers();
    my @pol_names = map {ref} @transformers;
    is_deeply(
        [grep {/block/ixms} @pol_names],
        [],
        'include/exclude pattern match had no "block" transformers',
    );
    # This odd construct arises because "any" can't be used with parens without syntax error(!)
    ok(
        @{[any {/builtinfunc/ixms} @pol_names]},
        'include/exclude pattern match had "builtinfunc" transformers',
    );
}

#-----------------------------------------------------------------------------
# Test the switch behavior

{
    my @switches = qw(
        -top
        -verbose
        -theme
        -severity
        -only
        -force
        -color
        -pager
        -allow-unsafe
        -mogrification-fatal
        -color-severity-highest
        -color-severity-high
        -color-severity-medium
        -color-severity-low
        -color-severity-lowest
    );

    # Can't use IO::Interactive here because we /don't/ want to check STDIN.
    my $color = -t *STDOUT ? $TRUE : $FALSE;

    my %undef_args = map { $_ => undef } @switches;
    my $c = Perl::ToPerl6::Config->new( %undef_args );
    $c = Perl::ToPerl6::Config->new( %undef_args );
    is( $c->force(),            0,      'Undefined -force');
    is( $c->only(),             0,      'Undefined -only');
    is( $c->severity(),         5,      'Undefined -severity');
    is( $c->theme()->rule(),    q{},    'Undefined -theme');
    is( $c->top(),              0,      'Undefined -top');
    is( $c->color(),            $color, 'Undefined -color');
    is( $c->pager(),            q{},    'Undefined -pager');
    is( $c->unsafe_allowed(),   0,      'Undefined -allow-unsafe');
    is( $c->verbose(),          4,      'Undefined -verbose');
    is( $c->mogrification_fatal(),  0,      'Undefined -mogrification-fatal');
    is( $c->color_severity_highest(),
        $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT,
        'Undefined -color-severity-highest'
    );
    is( $c->color_severity_high(),
        $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT,
        'Undefined -color-severity-high'
    );
    is( $c->color_severity_medium(),
        $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT,
        'Undefined -color-severity-medium'
    );
    is( $c->color_severity_low(),
        $PROFILE_COLOR_SEVERITY_LOW_DEFAULT,
        'Undefined -color-severity-low'
    );
    is( $c->color_severity_lowest(),
        $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT,
        'Undefined -color-severity-lowest'
    );

    my %zero_args = map { $_ => 0 }
        # Zero is an invalid Term::ANSIColor value.
        grep { ! / \A-color-severity- /smx } @switches;
    $c = Perl::ToPerl6::Config->new( %zero_args );
    is( $c->force(),     0,       'zero -force');
    is( $c->only(),      0,       'zero -only');
    is( $c->severity(),  1,       'zero -severity');
    is( $c->theme()->rule(),     q{},     'zero -theme');
    is( $c->top(),       0,       'zero -top');
    is( $c->color(),     $FALSE,  'zero -color');
    is( $c->pager(),     $EMPTY,  'zero -pager');
    is( $c->unsafe_allowed(),    0,       'zero -allow-unsafe');
    is( $c->verbose(),   4,       'zero -verbose');
    is( $c->mogrification_fatal(), 0, 'zero -mogrification-fatal');

    my %empty_args = map { $_ => q{} } @switches;
    $c = Perl::ToPerl6::Config->new( %empty_args );
    is( $c->force(),     0,       'empty -force');
    is( $c->only(),      0,       'empty -only');
    is( $c->severity(),  1,       'empty -severity');
    is( $c->theme->rule(),     q{},     'empty -theme');
    is( $c->top(),       0,       'empty -top');
    is( $c->color(),     $FALSE,  'empty -color');
    is( $c->pager(),     q{},     'empty -pager');
    is( $c->unsafe_allowed(),    0,       'empty -allow-unsafe');
    is( $c->verbose(),   4,       'empty -verbose');
    is( $c->mogrification_fatal(), 0, 'empty -mogrification-fatal');
    is( $c->color_severity_highest(), $EMPTY, 'empty -color-severity-highest');
    is( $c->color_severity_high(),   $EMPTY, 'empty -color-severity-high');
    is( $c->color_severity_medium(), $EMPTY, 'empty -color-severity-medium');
    is( $c->color_severity_low(),    $EMPTY, 'empty -color-severity-low');
    is( $c->color_severity_lowest(), $EMPTY, 'empty -color-severity-lowest');
}

#-----------------------------------------------------------------------------
# Test the -only switch

{
    my %profile = (
        'BasicTypes::Strings::FormatShellStrings' => {},
        'Variables::FormatHashKeys' => {},
    );

    my %pc_config = (-severity => 1, -only => 1, -profile => \%profile);
    my @transformers = Perl::ToPerl6::Config->new( %pc_config )->transformers();
    is(scalar @transformers, 2, '-only switch');
}

#-----------------------------------------------------------------------------
# Test the -single-transformer switch

{
    my %pc_config = ('-single-transformer' => 'Variables::FormatHashKeys');
    my @transformers = Perl::ToPerl6::Config->new( %pc_config )->transformers();
    is(scalar @transformers, 1, '-single-transformer switch');
}

#-----------------------------------------------------------------------------
# Test interaction between switches and defaults

{
    my %true_defaults = (
        force => 1, only  => 1, top => 10, 'allow-unsafe' => 1,
    );
    my %profile  = ( '__defaults__' => \%true_defaults );

    my %pc_config = (
        -force          => 0,
        -only           => 0,
        -top            => 0,
        '-allow-unsafe' => 0,
        -profile        => \%profile,
    );
    my $config = Perl::ToPerl6::Config->new( %pc_config );
    is( $config->force, 0, '-force: default is true, arg is false');
    is( $config->only,  0, '-only: default is true, arg is false');
    is( $config->top,   0, '-top: default is true, arg is false');
    is( $config->unsafe_allowed, 0, '-allow-unsafe: default is true, arg is false');
}

#-----------------------------------------------------------------------------
# Test named severity levels

{
    my %severity_levels = (gentle=>5, stern=>4, harsh=>3, cruel=>2, brutal=>1);
    while (my ($name, $number) = each %severity_levels) {
        my $config = Perl::ToPerl6::Config->new( -severity => $name );
        is( $config->severity(), $number, qq{Severity "$name" is "$number"});
    }
}


#-----------------------------------------------------------------------------
# Test exception handling

{
    my $config = Perl::ToPerl6::Config->new( -profile => 'NONE' );

    # Try adding a bogus transformer
    eval{ $config->apply_transform( -transformer => 'Bogus::Transformer') };
    like(
        $EVAL_ERROR,
        qr/Unable [ ] to [ ] create [ ] transformer/xms,
        'apply_transform w/ bad args',
    );

    # Try adding w/o transformer
    eval { $config->apply_transform() };
    like(
        $EVAL_ERROR,
        qr/The [ ] -transformer [ ] argument [ ] is [ ] required/xms,
        'apply_transform w/o args',
    );

    # Try using bogus named severity level
    eval{ Perl::ToPerl6::Config->new( -severity => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/The value for the global "-severity" option [(]"bogus"[)] is not one of the valid severity names/ms,
        'invalid severity'
    );

    # Try using vague -single-transformer option
    eval{ Perl::ToPerl6::Config->new( '-single-transformer' => q<.*> ) };
    like(
        $EVAL_ERROR,
        qr/matched [ ] multiple [ ] transformers/xms,
        'vague -single-transformer',
    );

    # Try using invalid -single-transformer option
    eval{ Perl::ToPerl6::Config->new( '-single-transformer' => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/did [ ] not [ ] match [ ] any [ ] transformers/xms,
        'invalid -single-transformer',
    );
}

#-----------------------------------------------------------------------------
# Test the -allow-unsafe switch
{
    my %profile = (
        'BasicTypes::Strings::FormatShellStrings' => {},
        'Variables::FormatHashKeys' => {},
    );

    # Pretend that ProhibitQuotedWordLists is actually unsafe
    no warnings qw(redefine once);
    local *Perl::ToPerl6::Transformer::BasicTypes::Strings::FormatShellStrings::is_safe = sub {return 0};

    my %safe_pc_config = (-severity => 1, -only => 1, -profile => \%profile);
    my @p = Perl::ToPerl6::Config->new( %safe_pc_config )->transformers();
    is(scalar @p, 1, 'Only loaded safe transformers without -unsafe switch');

    my %unsafe_pc_config = (%safe_pc_config, '-allow-unsafe' => 1);
    @p = Perl::ToPerl6::Config->new( %unsafe_pc_config )->transformers();
    is(scalar @p, 2, 'Also loaded unsafe transformers with -allow-unsafe switch');

    my %singular_pc_config = ('-single-transformer' => 'Variables::FormatHashKeys');
    @p = Perl::ToPerl6::Config->new( %singular_pc_config )->transformers();
    is(scalar @p, 1, '-single-transformer always loads Transformer, even if unsafe');
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/01_config.t_without_optional_dependencies.t
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
