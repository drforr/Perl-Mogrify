package Perl::Mogrify::Enforcer::BasicTypes::Integers::FormatBinaryLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Binary literals must be of form :2<0101_0101>};
Readonly::Scalar my $EXPL => q{Format binary literals};

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

    # 0b0101       --> :2<0101>
    # 0b010_101_01 --> :2<010_101_01>

    my $binary_integers = $doc->find('PPI::Token::Number::Binary');
    if ( $binary_integers and ref $binary_integers ) {
        for my $token ( @{ $binary_integers } ) {
            my $old_content = $token->content;

            #
            # Remove leading '0b'
            #
            $old_content =~ s{^0b}{}i;

            my $new_content = ':2<' . $old_content . '>';
            $token->set_content( $new_content );
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $binary_integers and ref $binary_integers;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Enforcer::BasicTypes::Integers::FormatBinaryLiterals - Format 0b0101 properly


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify> distribution.


=head1 DESCRIPTION

Perl6 binary literals have the format ':2<01_01_01_01>'. This enforcer reformats Perl5 binary literals to the Perl6 specification.

  0b01      -> :2<01>
  0b0101    -> :2<0101>
  0b010_10    -> :2<010_10>

If a binary literal is used anywhere than as a standalone number, this enforcer does not apply.

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
