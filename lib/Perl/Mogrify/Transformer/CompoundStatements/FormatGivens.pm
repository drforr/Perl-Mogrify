package Perl::Mogrify::Transformer::CompoundStatements::FormatGivens;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'given()' to 'given ()'};
Readonly::Scalar my $EXPL =>
    q{unless() needs whitespace in order to not be interpreted as a function call};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Statement::Given' }

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $token = $elem->first_element;
    return unless $token->content eq 'given';

    return unless $token->next_sibling;
    return if $token->next_sibling->isa('PPI::Token::Whitespace');

    my $space = PPI::Token::Whitespace->new();
    $space->set_content(' ');
    $token->insert_after( $space );

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::CompoundStatements::FormatGivens - Format given()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

While Perl6 conditionals allow parentheses, they need whitespace between the bareword C<given> and the opening parenthesis to avoid being interpreted as a function call:

  given(1) { } --> given (1) { }
  given (1) { } --> given (1) { }

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
