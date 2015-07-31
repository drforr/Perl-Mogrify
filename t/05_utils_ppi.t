#!perl

use 5.006001;
use strict;
use warnings;

use PPI;
use PPI::Token::Operator;
use PPI::Token::Word;
use Perl::ToPerl6::Utils::PPI qw< is_ppi_token_word dscanf >;

use Test::More tests => 14;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

can_ok('main', 'is_ppi_token_word');

ok !is_ppi_token_word(), 'Undef fails correctly';
ok !is_ppi_token_word(PPI::Token::Operator->new('.')),
    'Operator fails correctly';
ok !is_ppi_token_word(PPI::Token::Word->new('.'), '!' => 1),
    'Wrong word fails correctly';
ok is_ppi_token_word(PPI::Token::Word->new('.'), '.' => 1),
    'Correct word is matched';

#-----------------------------------------------------------------------------
#
# dscanf() testing
#
{
    # Note that $doc has to exist outside the dscanf() call, otherwise the
    # elements it refers to go away.
    #
    my $doc = PPI::Document->new(\'my %x');
    my $out = $doc->find( dscanf('my') );

    ok @{ $out } == 1, q{Found the correct number of 'my' tokens};

    isa_ok $out->[0], 'PPI::Token::Word';
    is $out->[0]->content, 'my', q{Found the correct content 'my'};
}
{
    my $doc = PPI::Document->new(\'my %x;');
    ok !$doc->find( dscanf('Readonly my %v => %d') ),
       q{No 'Readonly...' in 'my %x'};
}
{
    my $doc = PPI::Document->new(\'Readonly my %x;');
    ok !$doc->find( dscanf('Readonly my %v => %d') ),
       q{No 'Readonly my %v => %d' in 'Readonly my %x'};
}
{
    my $doc = PPI::Document->new(\'Readonly my %x;');
    eval { dscanf('Readonly my %z => %d') };
    ok $@, q{dscanf() doesn't understand modifier '%z'};
}
{
    # Note that $doc has to exist outside the dscanf() call, otherwise the
    # elements it refers to go away.
    #
    my $doc = PPI::Document->new(\'Readonly my $ANSWER => 42');
    my $out = $doc->find( dscanf('Readonly my %sv => %d') );

    ok @{ $out } == 1,
       q{Matched 'Readonly my %sv => %d'};

    isa_ok $out->[0],
           'PPI::Token::Word';
    is $out->[0]->content,
       'Readonly',
       q{Found the correct content 'Readonly'};
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/05_utils_ppi.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
