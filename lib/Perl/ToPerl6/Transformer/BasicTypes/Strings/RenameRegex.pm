package Perl::ToPerl6::Transformer::BasicTypes::Strings::RenameRegex;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{qr{...} is now rx{...} - Does not alter the contents of qr{...}};
Readonly::Scalar my $EXPL =>
    q{qr{...} is now written as rx{...} - The contents are not rewritten};

#-----------------------------------------------------------------------------

sub run_after            { return 'BasicTypes::Strings::AddWhitespace' }
sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           { return 'PPI::Token::QuoteLike::Regexp' }

#-----------------------------------------------------------------------------

#
# Note to the reader:
#
# A PPI::Token::QuoteLike::Regexp object contains a single string which has the
# entire 'qr{...}' token. Therefore we can't add a Token::Whitespace between
# the 'qr' and '{..}' like we can with loops and conditionals.
#

sub transform {
    my ($self, $elem, $doc) = @_;

    my $content = $elem->content;

    $content =~ s{^qr}{rx};

    $elem->set_content( $content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::BasicTypes::Strings::RenameRegex - Format regexps correctly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 regexps now use rx{}

  qr{} --> rx{}

Transforms qr{} outside of comments, heredocs, strings and POD.

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
