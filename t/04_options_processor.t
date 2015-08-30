#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::OptionsProcessor;
use Perl::ToPerl6::Utils qw< :booleans >;
use Perl::ToPerl6::Utils::Constants qw< :color_necessity >;

use Test::More tests => 56;

#-----------------------------------------------------------------------------

{
    # Can't use IO::Interactive here because we /don't/ want to check STDIN.
    my $color = -t *STDOUT ? $TRUE : $FALSE;

    my $processor = Perl::ToPerl6::OptionsProcessor->new();
    is($processor->force(),    0,           'native default force');
    is($processor->in_place(), 0,           'native default in-place');
    is($processor->detail(),   2,           'native default detail');
    is($processor->only(),     0,           'native default only');
    is($processor->necessity(), 5,           'native default necessity');
    is($processor->theme(),    q{},         'native default theme');
    is($processor->top(),      0,           'native default top');
    is($processor->color(),    $color,      'native default color');
    is($processor->pager(),    q{},         'native default pager');
    is($processor->verbose(),  4,           'native default verbose');
    is_deeply($processor->include(), [],    'native default include');
    is_deeply($processor->exclude(), [],    'native default exclude');
    is($processor->color_necessity_highest(),
                               $PROFILE_COLOR_NECESSITY_HIGHEST_DEFAULT,
                               'native default color-necessity-highest');
    is($processor->color_necessity_high(),
                               $PROFILE_COLOR_NECESSITY_HIGH_DEFAULT,
                               'native default color-necessity-high');
    is($processor->color_necessity_medium(),
                               $PROFILE_COLOR_NECESSITY_MEDIUM_DEFAULT,
                               'native default color-necessity-medium');
    is($processor->color_necessity_low(),
                               $PROFILE_COLOR_NECESSITY_LOW_DEFAULT,
                               'native default color-necessity-low');
    is($processor->color_necessity_lowest(),
                               $PROFILE_COLOR_NECESSITY_LOWEST_DEFAULT,
                               'native default color-necessity-lowest');
    is_deeply($processor->program_extensions(), [],
                               'native default program extensions');
}

#-----------------------------------------------------------------------------

{
    my %user_defaults = (
         force                    => 1,
         'in-place'               => 0,
         detail                   => 0,
         only                     => 1,
         necessity                => 4,
         theme                    => 'pbp',
         top                      => 50,
         color                    => $FALSE,
         pager                    => 'less',
         verbose                  => 7,
         include                  => 'foo bar',
         exclude                  => 'baz nuts',
         'color-necessity-highest' => 'chartreuse',
         'color-necessity-high'    => 'fuschia',
         'color-necessity-medium'  => 'blue',
         'color-necessity-low'     => 'gray',
         'color-necessity-lowest'  => 'scots tartan',
         'program-extensions'     => '.PL .pl .t',
    );

    my $processor = Perl::ToPerl6::OptionsProcessor->new( %user_defaults );
    is($processor->force(),    1,             'user default force');
    is($processor->in_place(), 0,             'user default in_place');
    is($processor->detail(),   0,             'user default detail');
    is($processor->only(),     1,             'user default only');
    is($processor->necessity(), 4,             'user default necessity');
    is($processor->theme(),    'pbp',         'user default theme');
    is($processor->top(),      50,            'user default top');
    is($processor->color(),    $FALSE,        'user default color');
    is($processor->pager(),    'less',        'user default pager');
    is($processor->verbose(),  7,             'user default verbose');
    is_deeply($processor->include(),
              [ qw(foo bar) ], 'user default include');
    is_deeply($processor->exclude(),
              [ qw(baz nuts)], 'user default exclude');
    is($processor->color_necessity_highest(),
                                'chartreuse', 'user default color_necessity_highest');
    is($processor->color_necessity_high(),
                                'fuschia',  'user default color_necessity_high');
    is($processor->color_necessity_medium(),
                                'blue',     'user default color_necessity_medium');
    is($processor->color_necessity_low(),
                                'gray',     'user default color_necessity_low');
    is($processor->color_necessity_lowest(),
                                'scots tartan', 'user default color_necessity_lowest');
    is_deeply($processor->program_extensions(), [ qw(.PL .pl .t) ],
                                            'user default program-extensions');
}

#-----------------------------------------------------------------------------

{
    my $processor = Perl::ToPerl6::OptionsProcessor->new( 'colour' => 1 );
    is($processor->color(), $TRUE, 'user default colour true');

    $processor = Perl::ToPerl6::OptionsProcessor->new( 'colour' => 0 );
    is($processor->color(), $FALSE, 'user default colour false');

    $processor = Perl::ToPerl6::OptionsProcessor->new(
         'colour-necessity-highest'   => 'chartreuse',
         'colour-necessity-high'      => 'fuschia',
         'colour-necessity-medium'    => 'blue',
         'colour-necessity-low'       => 'gray',
         'colour-necessity-lowest'    => 'scots tartan',
    );
    is( $processor->color_necessity_highest(),
        'chartreuse',       'user default colour-necessity-highest' );
    is( $processor->color_necessity_high(),
        'fuschia',          'user default colour-necessity-high' );
    is( $processor->color_necessity_medium(),
        'blue',             'user default colour-necessity-medium' );
    is( $processor->color_necessity_low(),
        'gray',             'user default colour-necessity-low' );
    is( $processor->color_necessity_lowest(),
        'scots tartan',     'user default colour-necessity-lowest' );

    $processor = Perl::ToPerl6::OptionsProcessor->new(
         'color-necessity-5'    => 'chartreuse',
         'color-necessity-4'    => 'fuschia',
         'color-necessity-3'    => 'blue',
         'color-necessity-2'    => 'gray',
         'color-necessity-1'    => 'scots tartan',
    );
    is( $processor->color_necessity_highest(),
        'chartreuse',       'user default color-necessity-5' );
    is( $processor->color_necessity_high(),
        'fuschia',          'user default color-necessity-4' );
    is( $processor->color_necessity_medium(),
        'blue',             'user default color-necessity-3' );
    is( $processor->color_necessity_low(),
        'gray',             'user default color-necessity-2' );
    is( $processor->color_necessity_lowest(),
        'scots tartan',     'user default color-necessity-1' );

    $processor = Perl::ToPerl6::OptionsProcessor->new(
         'colour-necessity-5'    => 'chartreuse',
         'colour-necessity-4'    => 'fuschia',
         'colour-necessity-3'    => 'blue',
         'colour-necessity-2'    => 'gray',
         'colour-necessity-1'    => 'scots tartan',
    );
    is( $processor->color_necessity_highest(),
        'chartreuse',       'user default colour-necessity-5' );
    is( $processor->color_necessity_high(),
        'fuschia',          'user default colour-necessity-4' );
    is( $processor->color_necessity_medium(),
        'blue',             'user default colour-necessity-3' );
    is( $processor->color_necessity_low(),
        'gray',             'user default colour-necessity-2' );
    is( $processor->color_necessity_lowest(),
        'scots tartan',     'user default colour-necessity-1' );
}

#-----------------------------------------------------------------------------

{
    my $processor = Perl::ToPerl6::OptionsProcessor->new( pager => 'foo' );
    is($processor->color(), $FALSE, 'pager set turns off color');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my %invalid_defaults = (
        foo => 1,
        bar => 2,
    );

    eval { Perl::ToPerl6::OptionsProcessor->new( %invalid_defaults ) };
    like(
        $EVAL_ERROR,
        qr/"foo" [ ] is [ ] not [ ] a [ ] supported [ ] option/xms,
        'First invalid default',
    );
    like(
        $EVAL_ERROR,
        qr/"bar" [ ] is [ ] not [ ] a [ ] supported [ ] option/xms,
        'Second invalid default',
    );

}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/04_defaults.t_without_optional_dependencies.t
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
