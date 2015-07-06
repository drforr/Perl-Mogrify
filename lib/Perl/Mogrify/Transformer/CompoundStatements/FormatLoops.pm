package Perl::Mogrify::Transformer::CompoundStatements::FormatLoops;

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
sub applies_to           { return 'PPI::Structure::For' }

#-----------------------------------------------------------------------------

my %conditional = (
    for     => 'loop',
    foreach => 'loop',
);

sub _structure_has_semicolon {
    my ($elem) = @_;
    $elem = $elem->child(1);
    while ( $elem ) {
        return 1 if $elem->isa('PPI::Token::Structure');
        $elem = $elem->next_sibling;
    }
    return;
}

sub _is_c_style {
    my ($elem) = @_;
    $elem = $elem->child(1);
    while ( $elem->next_sibling ) {
        return 1 if $elem->isa('PPI::Statement::Null');
        return 1 if $elem->isa('PPI::Statement') and
                    _structure_has_semicolon($elem);
        $elem = $elem->next_sibling;
    }
    return;
}

sub transform {
    my ($self, $elem, $doc) = @_;
    return unless _is_c_style($elem);

    $elem->sprevious_sibling->set_content('loop');
    if ( !$elem->previous_sibling->isa('PPI::Token::Whitespace') ) {
        my $whitespace = PPI::Token::Whitespace->new(' ');
        $elem->insert_before($whitespace);
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::CompoundStatements::FormatLoops - Format for(;;) loops


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 changes C-style C<for> loops to use the name C<loop>:

  for(@a) --> for (@a)
  for($i=0;$i<1;$i++) --> loop ($i=0;$i<1;$i++)

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
