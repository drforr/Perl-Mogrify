#!perl

use 5.006001;
use strict;
use warnings;

use Readonly;


use PPI::Document qw< >;
use PPI::Statement::Break qw< >;
use PPI::Statement::Compound qw< >;
use PPI::Statement::Data qw< >;
use PPI::Statement::End qw< >;
use PPI::Statement::Expression qw< >;
use PPI::Statement::Include qw< >;
use PPI::Statement::Null qw< >;
use PPI::Statement::Package qw< >;
use PPI::Statement::Scheduled qw< >;
use PPI::Statement::Sub qw< >;
use PPI::Statement::Unknown qw< >;
use PPI::Statement::UnmatchedBrace qw< >;
use PPI::Statement::Variable qw< >;
use PPI::Statement qw< >;
use PPI::Token::Word qw< >;

use Perl::Mogrify::Utils::PPI qw< :all >;

use Test::More tests => 64;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

my @ppi_statement_classes = qw{
    PPI::Statement
        PPI::Statement::Package
        PPI::Statement::Include
        PPI::Statement::Sub
            PPI::Statement::Scheduled
        PPI::Statement::Compound
        PPI::Statement::Break
        PPI::Statement::Data
        PPI::Statement::End
        PPI::Statement::Expression
            PPI::Statement::Variable
        PPI::Statement::Null
        PPI::Statement::UnmatchedBrace
        PPI::Statement::Unknown
};

my %instances = map { $_ => $_->new() } @ppi_statement_classes;
$instances{'PPI::Token::Word'} = PPI::Token::Word->new('foo');

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'is_ppi_token_word');

#-----------------------------------------------------------------------------
#  is_ppi_token_word tests

{
    ok(
        ! is_ppi_token_word( undef ),
        'is_ppi_token_word( undef )',
    );
    ok(
        ! is_ppi_token_word( $instances{'PPI::Token::Operator'} ),
        'is_ppi_token_word( PPI::Token::Operator )',
    );
    ok(
        is_ppi_token_word( $instances{'PPI::Token::Word'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement )',
    );
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
