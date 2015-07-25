package Perl::ToPerl6::Transformer::Arrays::FormatArrayQws;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_ppi_token_quotelike_words_like };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform qw(...) to qw (...)};
Readonly::Scalar my $EXPL =>
    q{qw<>, qw{} &c are fine, but qw() is now a function call. Add ' ' to avoid this};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                             }
sub default_severity     { return $SEVERITY_HIGHEST              }
sub default_themes       { return qw(core bugs)                  }
sub applies_to           {
    return sub {
        is_ppi_token_quotelike_words_like($_[1],qr{^qw\(})
    }
}

#-----------------------------------------------------------------------------

#
# Note to the reader:
#
# A PPI::Token::QuoteLike::Words object contains a single string which has the
# entire 'qw{...}' token. Therefore we can't add a Token::Whitespace between
# the 'qw' and '{..}' like we can with loops and conditionals.
#

sub transform {
    my ($self, $elem, $doc) = @_;
    my $old_content = $elem->content;

    $old_content =~ s{^qw\(}{qw (};

    $elem->set_content( $old_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Array::FormatArrayQws - Format qw() to qw ()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6> distribution.


=head1 DESCRIPTION

Perl6 qw() operates almost exactly like Perl5 qw() but with one corner case - C<qw(a b c)>, like any bareword followed by an open parenthesis, is treated as a function call. This Transformer places a whitespace between C<qw> and C<(...)> in order to disambiguate, like so:

  qw(a b c) --> qw (a b c)
  qw{a b c} --> qw{a b c}
  qw<a b c> --> qw{a b c}

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
