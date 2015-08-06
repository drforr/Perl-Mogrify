package Perl::ToPerl6::Transformer::CompoundStatements::FormatUntils;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_ppi_statement_compound };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'until()' to 'until ()'};
Readonly::Scalar my $EXPL =>
    q{unless() needs whitespace in order to not be interpreted as a function call};

#-----------------------------------------------------------------------------

my %map = (
    until => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_statement_compound($_[1], %map) and
        $_[1]->first_element->next_sibling and
        not $_[1]->first_element->next_sibling->isa('PPI::Token::Whitespace')
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    $elem->first_element->insert_after(
        PPI::Token::Whitespace->new(' ')
    );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::CompoundStatements::FormatUntils - Format until()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

While Perl6 conditionals allow parentheses, they need whitespace between the bareword C<until> and the opening parenthesis to avoid being interpreted as a function call:

  until(1) { } --> until (1) { }
  until (1) { } --> until (1) { }

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
