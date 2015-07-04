package Perl::Mogrify::Transformer::BasicTypes::Integers::FormatOctalLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transforms 0o11 and 011 into :8<11>};
Readonly::Scalar my $EXPL => q{Perl6 octal integers look like :8<0011>};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Number::Octal' }

#-----------------------------------------------------------------------------

#
# 0o0123 --> :8<0123>
# 0o0123_4567 --> :8<0123_4567>
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->content;

    #
    # Remove leading '0o' or '0' and optional leading underscore
    #
    $old_content =~ s{^0[o]?[_]?}{}i;

    my $new_content = ':8<' . $old_content . '>';
    $elem->set_content( $new_content );

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Integers::FormatOctalLiterals - Format 0o0123 properly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 octal literals have the format ':8<01_01_01_01>'. PPI treats leading-0 and 0o numbers the same. Existing separators are preserved:

  001      -> :8<01>
  0o0167   -> :8<0167>
  0o010_10 -> :8<010_10>
  0o_010_10 -> :8<010_10>

Transforms octal numbers outside of comments, heredocs, strings and POD.
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
