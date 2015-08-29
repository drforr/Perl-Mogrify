package Perl::ToPerl6::Transformer::Variables::ReplaceNegativeIndex;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_ppi_token_word };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Negative array indexes now need [*-1] notation};
Readonly::Scalar my $EXPL => q{Negative array indexes now need [*-1] notation};

#-----------------------------------------------------------------------------

#
# That way we don't have to deal with the integer conversions.
#
sub run_before           {
    return 'BasicTypes::Integers::RewriteBinaryNumbers',
           'BasicTypes::Integers::RewriteOctalNumbers',
           'BasicTypes::Integers::RewriteHexNumbers'
}

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
#
# Don't test the subscript type because the [-N] may be after a {}.
#
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Symbol') and
        $_[1]->snext_sibling and
        ( $_[1]->snext_sibling->isa('PPI::Structure::Subscript') or
          $_[1]->snext_sibling->isa('PPI::Token::Operator') )
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
    my $head = $elem;

    while ( $head = $head->snext_sibling ) {
        next unless $head->isa('PPI::Structure::Subscript') and
                    $head->start eq '[';
        if ( $head->schild(0)->isa('PPI::Statement::Expression') ) {
            if ( $head->schild(0)->schild(0)->isa('PPI::Token::Number') and
                 $head->schild(0)->schild(0)->content =~ /^ [-] /x ) {
                #
                # Don't use the operator '*' lest it get confused. This way
                # the code is still syntactically correct.
                #
                $head->schild(0)->schild(0)->insert_before(
                    PPI::Token::Word->new('*')
                );
            }
        }
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Variables::ReplaceNegativeIndex - Perl6 now uses [*-1] notation to represent negative indices.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 uses the new open-ended range notation C<[*-1]> to access the last element of an array:

  $x[-1] --> $x[*-1]
  $x->[-1] --> $x->[*-1]

Transforms variables outside of comments, heredocs, strings and POD.

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
