package Perl::ToPerl6::Transformer::CompoundStatements::RewriteMapGreps;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    is_ppi_token_word
    replace_remainder_with_block
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'given()' to 'given ()'};
Readonly::Scalar my $EXPL =>
    q{unless() needs whitespace in order to not be interpreted as a function call};

#-----------------------------------------------------------------------------

my %map = (
    map  => 1,
    grep => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1], %map) and
        $_[1]->snext_sibling
    }
}

#-----------------------------------------------------------------------------

sub _is_end_of_expression {
    $_[1]->isa('PPI::Token::Operator') and
    $_[1]->content eq ',';
}

sub transform {
    my ($self, $elem, $doc) = @_;

#
# XXX This is worrisome, as this test should not need to be done.
# XXX The applies_to() method above implies that $elem should have an
# XXX snext_sibling by the time it gets here.
#
    return unless $elem->snext_sibling;
    my $token = $elem->snext_sibling;

    if ( $token->isa('PPI::Structure::Block') and
         $token->start and
         $token->start eq '{' and
         $token->finish and
         $token->finish eq '}' ) {
         return if $token->snext_sibling and
                _is_end_of_expression(undef,$token->snext_sibling);
        my $comma = PPI::Token::Operator->new(',');
        $token->insert_after( $comma );
    }
    else {
        replace_remainder_with_block($token, \&_is_end_of_expression );
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::CompoundStatements::RewriteMapGreps - Format map{}, grep{}


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 unifies C<map{}> and C<grep{}> with the rest of the function calls, in that the first argument must be a block, and the arguments must be separated with commas. This transformer adds the block where needed, and inserts the comma as required:

  map {$_++} @x; --> map {$_++}, @x;
  map /x/ @x; --> map {/x/}, @x;
  grep {$_++} @x; --> grep {$_++}, @x;
  grep /x/ @x; --> grep {/x/}, @x;

=head1 CONFIGURATION

This Transformer is not configurable except for the standard options.

=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 2015 Jeffrey Goff

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
