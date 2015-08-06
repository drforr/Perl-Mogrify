package Perl::ToPerl6::Transformer::Instances::Creation;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_ppi_token_word dscanf make_ppi_structure_list };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'new Foo()' to 'Foo->new()'};
Readonly::Scalar my $EXPL => q{Transform 'new Foo()' to 'Foo->new()'};

#-----------------------------------------------------------------------------

#
# Run before '->' --> '.' conversion so we don't have to worry.
#
sub run_before           { return 'Operators::FormatOperators' }
sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        dscanf('new %W %L')->(@_) ||
        dscanf('new %W %s')->(@_)
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $token = $elem->clone;
    if ( $elem->snext_sibling->snext_sibling->isa('PPI::Token::Quote') ) {
        my $new_list = make_ppi_structure_list;
        my $new_statement = PPI::Statement->new;
        $new_list->add_element($new_statement);
        $new_statement->add_element(
            $elem->snext_sibling->snext_sibling->clone
        );

        while ( $token and $token->next_sibling ) {
            last if $token->content eq ',';
            $new_statement->add_element($token->clone);
            $token = $token->next_sibling;
        }
        $elem->snext_sibling->snext_sibling->remove;
        $elem->snext_sibling->insert_after($new_list);
        $elem->snext_sibling->snext_sibling->next_sibling->remove if
            $elem->snext_sibling->snext_sibling->next_sibling->isa('PPI::Token::Whitespace');
    }
    $elem->snext_sibling->insert_after($token);
    $elem->snext_sibling->insert_after(
        PPI::Token::Operator->new('->')
    );
    $elem->next_sibling->delete() if
        $elem->next_sibling->isa('PPI::Token::Whitespace');
    $elem->delete;

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Instances::Creation - Indirect object notation no longer allowed.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 no longer supports Perl5-style indirect object notation.

  new Foo(); --> Foo.new();

Transforms 'new' statements outside of comments, heredocs, strings and POD.

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
