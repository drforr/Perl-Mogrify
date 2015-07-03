package Perl::Mogrify::Enforcer::BasicTypes::Strings::FormatRegexp;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{qr{...} is now rx{...} - This does NOT convert to the new grammar.};
Readonly::Scalar my $EXPL =>
    q{Format qr{...} as rx{...}. Does not alter the contents to perl6};

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

    # qr{...} --> rx{...}

    my $string = $doc->find('PPI::Token::QuoteLike::Regexp');
    if ( $string and ref $string ) {
        for my $token ( @{ $string } ) {
            my $content = $token->content;

            if ( $content =~ s{<<(\w+)}{q:to/$1/} ) {
            }

            #
            # XXX This breaks PPI::Token::HereDoc encapsulation.
            #
            elsif ( $content =~ s{<<'(\s*(\w+))'}{q:to/$2/} ) {
                my $heredoc = $1;
                my $stripped = $2;
                for my $line ( @{ $token->{_heredoc} } ) {
                    next unless $line =~ /$heredoc/;
                    $line = $stripped;
                    last;
                }
                $token->{_terminator} = $1;
            }

            $token->set_content( $content );
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $string and ref $string;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Enforcer::BasicTypes::Strings::FormatHereDocs - Format <<EOF constructs correctly


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 heredocs no longer need to be quoted

Perl6 interpolation of variables lets you use C<{$x}> where the C<{}> can contain any expression. This enforcer reformats C<${x}> to C<{$x}> in your interpolated strings.

  "The $x bit"      --> "The $x bit"
  "The ${x}rd bit"  --> "The {$x}rd bit"
  "The \${x}rd bit" --> "The \$\{x\}rd bit"

This enforcer only operates in quoted strings, heredocs present another issue.

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
