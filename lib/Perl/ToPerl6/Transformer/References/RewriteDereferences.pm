package Perl::ToPerl6::Transformer::References::RewriteDereferences;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform %x{a} to %x{'a'}};
Readonly::Scalar my $EXPL =>
    q{Perl6 assumes that braces are code blocks, so any content must be compilable};

#-----------------------------------------------------------------------------

sub run_after            { return 'Operators::FormatOperators' }
sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Cast') and
        $_[1]->next_sibling and
        $_[1]->next_sibling->isa('PPI::Structure::Block') and
        $_[1]->next_sibling->start->content eq '{' and
        $_[1]->next_sibling->finish->content eq '}'
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
    my $next = $elem->next_sibling;

    $next->start->set_content('(');
    $next->finish->set_content(')');
    if ( $elem->content eq '$#' ) {
        $elem->set_content('@');
        $elem->snext_sibling->insert_after(
            PPI::Token::Word->new('end')
        );
        $elem->snext_sibling->insert_after(
            PPI::Token::Operator->new('.')
        );
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::References::RewriteDereferences - Transform %{$foo} to %($foo)


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 dereferencing uses C<%()> and C<@()> because C<()> would be a code block otherwise:

  %{$foo} --> %($foo)
  %$foo   --> %$foo
  @{$foo} --> @($foo)
  @$foo   --> @$foo

Transforms dereferences outside of comments, heredocs, strings and POD.

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
