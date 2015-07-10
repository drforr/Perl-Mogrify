package Perl::Mogrify::Transformer::References::FormatDereferences;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform %x{a} to %x{'a'}};
Readonly::Scalar my $EXPL =>
    q{Perl6 assumes that braces are code blocks, so any content must be compilable};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Cast') and
        $_[1]->next_sibling->isa('PPI::Structure::Block') and
        $_[1]->next_sibling->start->content eq '{' and
        $_[1]->next_sibling->finish->content eq '}'
        
# Redundant checks for the tests below.
#
#        not $_[1]->next_sibling->isa('PPI::Token::Symbol') and
#        # Not two casts in a row, like \% in \%{"$pack\:\:SUBS"} .
#        not( $_[1]->next_sibling->isa('PPI::Token::Cast') and
#             $_[1]->next_sibling->content eq '\\' ) and
#        # \( $x, $y ) are not the constructs we're looking for.
#        not( $_[1]->next_sibling->isa('PPI::Structure::List') and
#             $_[1]->next_sibling->content eq '\\' )
    }
}

#-----------------------------------------------------------------------------

#
# %foo{'a'} --> %foo{'a'}
# %foo{a}   --> %foo{'a'}
#
sub transform {
    my ($self, $elem, $doc) = @_;
    my $next = $elem->next_sibling;

    # %{...} becomes %(...). Same with @{...} and ${...}.
    $next->start->set_content('(');
    $next->finish->set_content(')');

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::References::FormatDereferences - Transform %{$foo} to %($foo)


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
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
