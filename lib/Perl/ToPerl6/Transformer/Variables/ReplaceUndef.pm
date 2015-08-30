package Perl::ToPerl6::Transformer::Variables::ReplaceUndef;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    is_ppi_token_word
    remove_trailing_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{'undef' no longer exists, 'Any' is a reasonable approximation};
Readonly::Scalar my $EXPL =>
    q{'undef' no longer exists, 'Any' is a reasonable approximation};

#-----------------------------------------------------------------------------

my %map = (
    undef => 1
);

#-----------------------------------------------------------------------------

sub run_after            { return 'Operators::FormatOperators' }
sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1], %map)
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    if ( $elem->snext_sibling and
         $elem->snext_sibling->isa('PPI::Token::Symbol') and
         $elem->snext_sibling->snext_sibling and
         $elem->snext_sibling->snext_sibling->isa('PPI::Token::Operator') and
         $elem->snext_sibling->snext_sibling->content eq '->' ) {
        $elem->snext_sibling->snext_sibling->snext_sibling->insert_after(
            PPI::Token::Word->new(':delete')
        );
        $elem->snext_sibling->snext_sibling->set_content('.');
        remove_trailing_whitespace($elem);
        $elem->remove;
    }
    elsif ( $elem->snext_sibling and
         $elem->snext_sibling->isa('PPI::Token::Symbol') and
         $elem->snext_sibling->snext_sibling and
         $elem->snext_sibling->snext_sibling->isa('PPI::Structure::Subscript') ) {
        $elem->snext_sibling->snext_sibling->insert_after(
            PPI::Token::Word->new(':delete')
        );
        remove_trailing_whitespace($elem);
        $elem->remove;
    }
    else {
        $elem->set_content('Any');
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Variables::FormatSigils - Give variables their proper sigils.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 uses the sigil type as the data type now, and this is probably the most common operation people will want to do to their file. This transformer doesn't alter hash keys or array indices, those are left to transformers down the line:

  @foo = () --> @foo = ()
  $foo[1] --> @foo[1]
  %foo = () --> %foo = ()
  $foo{a} --> %foo{a} # Not %foo<a> or %foo{'a'} yet.

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
