package Perl::Mogrify::Transformer::BasicTypes::Integers::FormatOctalLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Octal literals must be of form :8<0123_4567>};
Readonly::Scalar my $EXPL => q{Format octal literals};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    return 1; # Can be anything.
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    # 0o0123 --> :8<0123>
    # 0o0123_4567 --> :8<0123_4567>

    my $octal_integers = $doc->find('PPI::Token::Number::Octal');
    if ( $octal_integers and ref $octal_integers ) {
        for my $token ( @{ $octal_integers } ) {
            my $old_content = $token->content;

            #
            # Remove leading '0o'
            #
            $old_content =~ s{^0o}{}i;

            my $new_content = ':8<' . $old_content . '>';
            $token->set_content( $new_content );
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $octal_integers and ref $octal_integers;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Integers::FormatOctalLiterals - Format 0o0123 properly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 octal literals have the format ':8<0123_4567>'. This enforcer reformats Perl5 octal literals to the Perl6 specification:

  0o12      -> :8<12>
  0o1234    -> :8<1234>
  0o123_45  -> :8<123_45>

If an octal literal is used anywhere than as a standalone number, this enforcer does not apply.

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
