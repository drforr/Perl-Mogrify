package Perl::Mogrify::Enforcer::BasicTypes::Integers::FormatHexLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Hex literals must be of form :16<DEAD_BEEF>};
Readonly::Scalar my $EXPL => q{Format hexadecimal literals};

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

    # 0x1_2eF -> :16<1_2ef>

    my $hex_integers = $doc->find('PPI::Token::Number::Hex');
    if ( $hex_integers and ref $hex_integers ) {
        for my $token ( @{ $hex_integers } ) {
            my $old_content = $token->content;

            #
            # Remove leading '0x'
            #
            $old_content =~ s{^0x}{}i;

            my $new_content = ':16<' . $old_content . '>';
            $token->set_content( $new_content );
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $hex_integers and ref $hex_integers;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Enforcer::BasicTypes::Integers::FormatHexLiterals - Format 0x1234 properly


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 hexadecimal literals have the format ':16<DEAD_BEEF>'. This enforcer reformats Perl5 hexadecimal literals to the Perl6 specification:

  0x12      -> :16<12>
  0xEf      -> :16<Ef>
  0x12ef    -> :16<12ef>
  0xEFa_abc -> :16<EFa_abc>

If a hexadecimal literal is used anywhere than as a standalone number, this enforcer does not apply.

=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.

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
