package Perl::ToPerl6::Transformer::Regexes::StandardizeDelimiters;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regex delimiters can no longer be alphanumeric};
Readonly::Scalar my $EXPL => q{Regex delimiters can no longer be alphanumeric};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Regexp') and
        $_[1]->{sections}[0]{type} =~ /[a-zA-Z0-9#]/
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my @content;
    for ( @{ $elem->{sections} } ) {
        my $content = substr( $elem->content, $_->{position}, $_->{size} );
        $content =~ s{/}{\\/}g; # XXX this could be a problem.
        $_->{position}--; # Account for the eventual lack of whitespace.
        $_->{type} = '//';
        push @content, $content;
    }

    my ( $operator ) = $elem->content =~ m{^(m|s|y|tr)};
    my $num_modifiers = keys %{ $elem->get_modifiers };
    my $modifiers = substr( $elem->content, -$num_modifiers, $num_modifiers );

    my $new_content = $operator . '/' .
                      join('/', @content) . '/' .
                      $modifiers;

    $elem->{separator} = '/';
    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Regexp::StandardizeDelimiters - Regexen can no longer have alphanumeric delimiters


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 regular expression delimiters can no longer be alphanumeric:

  m mfoom --> m/foo/
  m mf/oom --> m/f\/oo/ # Escape the new delimiter
  m f\foof --> m/\foo/ # Otherwise do not alter the contents.

Transforms regular expressions outside of comments, heredocs, strings and POD.

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
