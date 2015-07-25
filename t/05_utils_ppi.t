#!perl

use 5.006001;
use strict;
use warnings;

use PPI::Token::Operator;
use PPI::Token::Word;
use Perl::ToPerl6::Utils::PPI qw< is_ppi_token_word >;

use Test::More tests => 5;

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
