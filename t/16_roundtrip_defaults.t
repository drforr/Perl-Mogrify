#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::Config;
use Perl::ToPerl6::ProfilePrototype;
use Perl::ToPerl6::Utils qw{ :characters :severities };

use Test::Deep;
use Test::More;

#-----------------------------------------------------------------------------

my $default_configuration =
    Perl::ToPerl6::Config->new(
        -profile => $EMPTY,
        -necessity => 1,
        -theme => 'core',
    );
my @default_transformers = $default_configuration->transformers();

my $transformer_test_count;

$transformer_test_count = 4 * @default_transformers;
foreach my $transformer (@default_transformers) {
    if (
            $transformer->parameter_metadata_available()
        and not $transformer->isa('Perl::ToPerl6::Transformer::Arrays::AddWhitespace')
    ) {
        $transformer_test_count += scalar @{$transformer->get_parameters()};
    }
}
my $test_count = 20 + $transformer_test_count;
plan tests => $test_count;

#-----------------------------------------------------------------------------

my $profile_generator =
    Perl::ToPerl6::ProfilePrototype->new(
        -transformers                   => \@default_transformers,
        '-comment-out-parameters'   => 0,
        -config                     => $default_configuration,
    );
my $profile = $profile_generator->to_string();

my $derived_configuration =
    Perl::ToPerl6::Config->new( -profile => \$profile );

#-----------------------------------------------------------------------------

my @derived_include = $derived_configuration->include();
my @default_include = $default_configuration->include();
cmp_deeply(
    \@derived_include,
    \@default_include,
    'include',
);

#-----------------------------------------------------------------------------

my @derived_exclude = $derived_configuration->exclude();
my @default_exclude = $default_configuration->exclude();
cmp_deeply(
    \@derived_exclude,
    \@default_exclude,
    'exclude',
);

#-----------------------------------------------------------------------------

my @derived_single_transformer = $derived_configuration->single_transformer();
my @default_single_transformer = $default_configuration->single_transformer();
cmp_deeply(
    \@derived_single_transformer,
    \@default_single_transformer,
    'single_transformer',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->force(),
    $default_configuration->force(),
    'force',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->detail(),
    $default_configuration->detail(),
    'detail',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->in_place(),
    $default_configuration->in_place(),
    'in_place',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->only(),
    $default_configuration->only(),
    'only',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->profile_strictness(),
    $default_configuration->profile_strictness(),
    'profile_strictness',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color(),
    $default_configuration->color(),
    'color',
);

#-----------------------------------------------------------------------------

cmp_ok(
    $derived_configuration->necessity(),
    q<==>,
    $default_configuration->necessity(),
    'necessity',
);

#-----------------------------------------------------------------------------

cmp_ok(
    $derived_configuration->top(),
    q<==>,
    $default_configuration->top(),
    'top',
);

#-----------------------------------------------------------------------------

cmp_ok(
    $derived_configuration->verbose(),
    q<==>,
    $default_configuration->verbose(),
    'verbose',
);

#-----------------------------------------------------------------------------

cmp_deeply(
    $derived_configuration->theme(),
    $default_configuration->theme(),
    'theme',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_necessity_highest(),
    $default_configuration->color_necessity_highest(),
    'color_necessity_highest',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_necessity_high(),
    $default_configuration->color_necessity_high(),
    'color_necessity_high',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_necessity_medium(),
    $default_configuration->color_necessity_medium(),
    'color_necessity_medium',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_necessity_low(),
    $default_configuration->color_necessity_low(),
    'color_necessity_low',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_necessity_lowest(),
    $default_configuration->color_necessity_lowest(),
    'color_necessity_lowest',
);

#-----------------------------------------------------------------------------

my @derived_program_extensions = $derived_configuration->program_extensions();
my @default_program_extensions = $default_configuration->program_extensions();
cmp_deeply(
    \@derived_program_extensions,
    \@default_program_extensions,
    'program_extensions',
);

#-----------------------------------------------------------------------------

my @derived_transformers = $derived_configuration->transformers();

my $transformer_counts_match =
    is(
        scalar @derived_transformers,
        scalar @default_transformers,
        'same transformer count'
    );

SKIP: {
    skip q{XXX Fix this later}, $transformer_test_count;
    skip
        q{because there weren't the same number of transformers},
            $transformer_test_count
        if not $transformer_counts_match;

    for (my $x = 0; $x < @default_transformers; $x++) {
        my $derived_transformer = $derived_transformers[$x];
        my $default_transformer = $default_transformers[$x];

        is(
            $derived_transformer->get_short_name(),
            $default_transformer->get_short_name(),
            'transformer names match',
        );
        is(
            $derived_transformer->get_necessity(),
            $default_transformer->get_necessity(),
            $default_transformer->get_short_name() . ' severities match',
        );
        is(
            $derived_transformer->get_themes(),
            $default_transformer->get_themes(),
            $default_transformer->get_short_name() . ' themes match',
        );

        if (
                $default_transformer->parameter_metadata_available()
            and not $default_transformer->isa('Perl::ToPerl6::Transformer::Arrays::FOrmatArrayQws')
        ) {
            # Encapsulation transformation alert!
            foreach my $parameter ( @{$default_transformer->get_parameters()} ) {
                my $parameter_name =
                    $default_transformer->__get_parameter_name( $parameter );

                cmp_deeply(
                    $derived_transformer->{$parameter_name},
                    $default_transformer->{$parameter_name},
                    $default_transformer->get_short_name()
                        . $SPACE
                        . $parameter_name
                        . ' match',
                );
            }
        }
    }
}


#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
