package Perl::ToPerl6::Transformer::BasicTypes::Strings::FormatHereDocs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform <<EOF to q:to/EOF/};
Readonly::Scalar my $EXPL => q{Perl6 heredocs now have more flexibility};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::HereDoc' }

#-----------------------------------------------------------------------------

#
# <<EOF --> q:to/EOF/
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $content = $elem->content;

    if ( $content =~ s{<<(\w+)}{q:to/$1/} ) {
    }

    #
    # XXX This breaks PPI::Token::HereDoc encapsulation.
    #
    elsif ( $content =~ s{<<'(\s*(\w+))'}{q:to/$2/} ) {
        my $heredoc = $1;
        my $stripped = $2;
        for my $line ( @{ $elem->{_heredoc} } ) {
            next unless $line =~ /$heredoc$/;
            $line = $stripped;
            last;
        }
        $elem->{_terminator} = $1;
    }

    $elem->set_content( $content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::BasicTypes::Strings::FormatHereDocs - Format <<EOF constructs correctly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 heredocs now no longer need to be quoted, and the indentation rules differ from perl5. Specifically the old workaround of C<< <<'  EOF' >> will have surprising results, because your entire heredoc will be indented by the whitespace amount:

  <<EOF; --> q:to/EOF/;
  EOF    --> EOF

  <<'  EOF'; --> q:to/EOF/;
    EOF      --> EOF

Transforms only heredocs, not POD or comments.

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
