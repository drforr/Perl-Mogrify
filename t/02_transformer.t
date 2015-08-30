#!perl

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Test::More tests => 20;


#-----------------------------------------------------------------------------

# Perl::ToPerl6::Transformer is an abstract class, so it can't be instantiated
# directly.  So we test it by declaring test classes that inherit from it.

package TransformerTest;
use base 'Perl::ToPerl6::Transformer';

package TransformerTestOverriddenDefaultMaximumTransformations;
use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

package main;
## use mogrify

my $p = TransformerTest->new();
isa_ok($p, 'TransformerTest');


local $EVAL_ERROR = undef;
eval { $p->transform(); 1 };
ok($EVAL_ERROR, 'abstract transform() throws exception');


is(
    $p->is_enabled(),
    undef,
    'is_enabled() initially returns undef',
);


# Test default application...
is($p->applies_to(), 'PPI::Element', 'applies_to()');


my $overridden_default = TransformerTestOverriddenDefaultMaximumTransformations->new();
isa_ok($overridden_default, 'TransformerTestOverriddenDefaultMaximumTransformations');

is(
    $overridden_default->is_enabled(),
    undef,
    'is_enabled() initially returns undef',
);

# Test default necessity...
is( $p->default_necessity(), 1, 'default_necessity()');
is( $p->get_necessity(), 1, 'get_necessity()' );

# Change necessity level...
$p->set_necessity(3);

# Test necessity again...
is( $p->default_necessity(), 1, q<default_necessity() hasn't changed.>);
is( $p->get_necessity(), 3, q<get_necessity() returns the new value.> );


# Test default theme...
is_deeply( [$p->default_themes()], [], 'default_themes()');
is_deeply( [$p->get_themes()], [], 'get_themes()');

# Change theme
$p->set_themes( qw(c b a) ); # unsorted

# Test theme again...
is_deeply( [$p->default_themes()], [], q<default_themes() hasn't changed.>);
is_deeply(
    [$p->get_themes()],
    [qw(a b c)],
    'get_themes() returns the new value, sorted.',
);

# Append theme
$p->add_themes( qw(f e d) ); # unsorted

# Test theme again...
is_deeply( [$p->default_themes()], [], q<default_themes() hasn't changed.>);
is_deeply(
    [$p->get_themes()],
    [ qw(a b c d e f) ],
    'get_themes() returns the new value, sorted.',
);


# Test format getter/setters
is( Perl::ToPerl6::Transformer::get_format, "%p\n", 'Default transformer format');

my $new_format = '%p %s [%t]';
Perl::ToPerl6::Transformer::set_format( $new_format ); # Set format
is( Perl::ToPerl6::Transformer::get_format, $new_format, 'Changed transformer format');

my $expected_string = 'TransformerTest 3 [a b c d e f]';
is( $p->to_string(), $expected_string, 'Stringification by to_string()');
is( "$p", $expected_string, 'Stringification by overloading');


#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/02_transformer.t_without_optional_dependencies.t
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
