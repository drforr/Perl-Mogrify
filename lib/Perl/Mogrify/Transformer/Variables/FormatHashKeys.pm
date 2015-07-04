package Perl::Mogrify::Transformer::Variables::FormatHashKeys;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform %x{a} to %x{'a'}};
Readonly::Scalar my $EXPL =>
    q{Perl6 assumes that braces are code blocks, so any content must be compilable};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Structure::Subscript' }

#-----------------------------------------------------------------------------

#
# %foo{'a'} --> %foo{'a'}
# %foo{a}   --> %foo{'a'}
#
sub transform {
    my ($self, $elem, $doc) = @_;
    return unless $elem->start eq '{' and $elem->finish eq '}';
    return unless $elem->sprevious_sibling->isa('PPI::Token::Symbol');

    my $bareword = $elem->child(0)->child(0);

    my $old_content = $bareword->content;

    my $new_content = "'" . $old_content . "'";

    my $word = PPI::Token::Quote::Single->new($new_content);

    $bareword->insert_after($word);
    $bareword->delete;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Variables::FormatHashKeys - Transform bareword hash keys into quoted hash keys


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Anything enclosed in braces should be compilable code in Perl6, and unfortunately bareword hash keys such as C<%foo{a}> are interpreted as C<%foo{a()}>, so when the function a() can't be found, the block fails to compile:

  %foo{a} --> %foo{'a'}
  %foo{'a'} --> %foo{'a'}

Using angle brackets as in C<< %foo<a> >> would be more Perl6 style, but this is a change that most people will immediately understand.

Transforms variables outside of comments, heredocs, strings and POD.

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
