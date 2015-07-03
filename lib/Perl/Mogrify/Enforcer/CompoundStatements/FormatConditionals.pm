package Perl::Mogrify::Enforcer::CompoundStatements::FormatConditionals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Conditionals such as if(), elsif() and unless() need whitespace};
Readonly::Scalar my $EXPL =>
    q{Format if(), elsif() and unless() to have a single whitespace};

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

    my $conditional = $doc->find('PPI::Statement::Compound');
    if ( $conditional and ref $conditional ) {
        for my $token ( @{ $conditional } ) {
            $token = $token->first_element;
            my $old_content = $token->content;
            if ( $old_content eq 'if' or
                 $old_content eq 'elsif' or
                 $old_content eq 'unless' ) {
                if ( $token->next_sibling and
                     !$token->next_sibling->isa('PPI::Token::Whitespace') ) {
                    my $space = PPI::Token::Whitespace->new();
                    $space->set_content( ' ' );
                    $token->insert_after( $space );
                }
            }
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $conditional and ref $conditional;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Enforcer::CompoundStatements::FormatConditionals - Format if(), elsif(), unless()


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 conditionals still allow parentheses, but must have whitespace between C<if> and C<()>:

  if(1) { } --> if (1) { }
  if (1) { } --> if (1) { }

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
