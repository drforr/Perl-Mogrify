package Perl::Mogrify::Transformer::CompoundStatements::FormatConditionals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'if()' to 'if ()'};
Readonly::Scalar my $EXPL =>
    q{if(), elsif() and unless() need whitespace in order to not be interpreted as function calls};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Statement::Compound' }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document { 1 }

#-----------------------------------------------------------------------------

my %conditional = (
    if => 1,
    elsif => 1,
    unless => 1,
);

sub transform {
    my ($self, $elem, $doc) = @_;

    my $token = $elem->first_element;

    my $old_content = $token->content;
    return unless $conditional{$old_content};
    return unless $token->next_sibling;
    return if $token->next_sibling->isa('PPI::Token::WHitespace');

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

Perl::Mogrify::Transformer::CompoundStatements::FormatConditionals - Format if(), elsif(), unless()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

While Perl6 conditionals allow parentheses, they need whitespace between the bareword C<if> and the opening parenthesis to avoid being interpreted as a function call:

  if(1) { } --> if (1) { }
  if (1) { } --> if (1) { }

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
