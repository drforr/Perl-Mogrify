package Perl::Mogrify::Transformer::BasicTypes::Integers::FormatHexLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transforms 0x0123 into :16<0123>};
Readonly::Scalar my $EXPL => q{Perl6 hexadecimal integers look like :16<0123>};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Number::Hex' }

#-----------------------------------------------------------------------------

#
# 0x1_2eF -> :16<1_2ef>
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->content;

    #
    # Remove leading '0x' and optional leading underscore
    #
    $old_content =~ s{^0x[_]?}{}i;

    my $new_content = ':16<' . $old_content . '>';
    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Integers::FormatHexLiterals - Format 0x1234 properly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 binary literals have the format ':2<01_01_01_01>'. Existig separators are preserved:

  0x01     -> :16<01>
  0x01ef   -> :16<01ef>
  0x010_ab -> :16<010_ab>
  0x_010_ab -> :16<010_ab>

Transforms hexadecimal numbers outside of comments, heredocs, strings and POD.

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
