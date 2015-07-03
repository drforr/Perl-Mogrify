package Perl::Mogrify::Enforcer::Operators::FormatTernaryOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Binary operators should be formatted to their Perl6 equivalents};
Readonly::Scalar my $EXPL =>
    q{Format binary operators to their Perl6 equivalents};

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

    # right    ?:

    my $operator = $doc->find('PPI::Token::Operator');
    if ( $operator and ref $operator ) {
        for my $token ( @{ $operator } ) {
            my $old_content = $token->content;
            if ( $old_content eq '?' ) { # XXX This is a special case.
                $token->set_content( '??' );
                while ( $token->next_sibling ) {
                    if ( $token->content eq ':' ) {
                        $token->set_content( '!!' );
                        last;
                    }
                    $token = $token->next_sibling;
                }
            }
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $operator and ref $operator;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Enforcer::Operators::FormatTernaryOperators - Format ?: ternary op


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

The Perl6 ternary operator is C<1 ?? 2 !! 3>:

  $x = $y > 1 ? 0 : 1 --> $x = $y > 1 ?? 0 !! 1;

This enforcer only operates on standalone ternary operators.

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
