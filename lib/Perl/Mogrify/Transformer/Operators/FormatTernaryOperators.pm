package Perl::Mogrify::Transformer::Operators::FormatTernaryOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{The ternary operator is now $x ?? 1 !! 2};
Readonly::Scalar my $EXPL =>
    q{The ternary operator has changed from ?: to ??!!};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Operator') and
        $_[1]->content eq '?'
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    # right    ?:

    my $old_content = $elem->content;

    $elem->set_content( '??' );

    my $current = $elem;
    while ( $current->next_sibling ) {
        if ( $current->content eq ':' ) {
            $current->set_content( '!!' );
            last;
        }
        $current = $current->next_sibling;
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Operators::FormatTernaryOperators - Format ?: ternary op


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

The Perl6 ternary operator is C<1 ?? 2 !! 3>:

  $x = $y > 1 ? 0 : 1 --> $x = $y > 1 ?? 0 !! 1;

Transform

Transforms ternary operators outside of comments, heredocs, strings and POD.

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
