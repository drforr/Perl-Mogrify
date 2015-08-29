package Perl::ToPerl6::Transformer::BasicTypes::Integers::RewriteHexNumbers;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transforms 0x0123 into :16<0123>};
Readonly::Scalar my $EXPL => q{Perl6 hexadecimal integers look like :16<0123>};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           { return 'PPI::Token::Number::Hex' }

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
    return unless $elem and $elem->content; # XXX Shouldn't be required, but it is.

    my $old_content = $elem->content;

    #
    # Remove leading '0x' and optional leading underscore
    #
    $old_content =~ s{^0x[_]?}{}i;
    $old_content =~ s{[_]$}{};
    $old_content =~ s{[_]+}{_}g;

    my $new_content = ':16<' . $old_content . '>';
    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::BasicTypes::Integers::RewriteHexNumbers - Format 0x1234 properly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 hexadecimal literals have the format ':16<01_78_ab_ef>'. Perl6 enforces the rule that separators must occur between digits, and only one separator character at a time:

  0x01        -> :16<01>
  0x01af      -> :16<01af>
  0x010_af    -> :16<010_af>
  0x_010__af_ -> :16<010_af>

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
