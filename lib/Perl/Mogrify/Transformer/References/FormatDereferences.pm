package Perl::Mogrify::Transformer::References::FormatDereferences;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform %x{a} to %x{'a'}};
Readonly::Scalar my $EXPL =>
    q{Perl6 assumes that braces are code blocks, so any content must be compilable};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Cast' }

#-----------------------------------------------------------------------------

#
# %foo{'a'} --> %foo{'a'}
# %foo{a}   --> %foo{'a'}
#
sub transform {
    my ($self, $elem, $doc) = @_;
    my $next = $elem->next_sibling;

    return if $next->isa('PPI::Token::Symbol');
    # Two casts in a row, like \% in \%{"$pack\:\:SUBS"} .
    return if $next->isa('PPI::Token::Cast') and
              $elem->content eq '\\';
    # \( $x, $y ) is not the construct we are looking for.
    return if $next->isa('PPI::Structure::List') and
              $elem->content eq '\\';

    return unless $next->isa('PPI::Structure::Block');
    return unless $next->start->content eq '{' and
                  $next->finish->content eq '}';

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
