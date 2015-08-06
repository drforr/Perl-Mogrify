package Perl::ToPerl6::Transformer::BasicTypes::Strings::AddWhitespace;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Rewrite interpolated strings};
Readonly::Scalar my $EXPL => q{Rewrite interpolated strings};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Quote') and
        $_[1]->{operator} and
        $_[1]->{operator} =~ / ^ q /x
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $new_content = $elem->content;

    $new_content =~ s{ ^ (q?q)[(] }{$1 (}x;

    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::BasicTypes::Strings::AddWhitespace - Add whitespace between q/qq and ()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 q() and qq() delimiters require whitespace if you're using round braces,
otherwise they get confused with a q() or qq() function:

  q(Hello world) --> q (Hello world)
  q[Hello world] --> q[Hello world]
  qq (Hello world) --> q (Hello world)
  qq[Hello world] --> qq[Hello world]

Transforms only interpolated strings outside of comments, heredocs and POD.

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
