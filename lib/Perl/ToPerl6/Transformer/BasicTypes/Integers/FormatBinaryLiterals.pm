package Perl::ToPerl6::Transformer::BasicTypes::Integers::FormatBinaryLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transforms 0b0011 into :2<0011>};
Readonly::Scalar my $EXPL => q{Perl6 binary integers look like :2<0011>};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Number::Binary' }

#-----------------------------------------------------------------------------

#
# 0b0101       --> :2<0101>
# 0b010_101_01 --> :2<010_101_01>
# 0b010__101_01 --> :2<010_101_01>
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->content;

    $old_content =~ s{^0b[_]?}{}i;
    $old_content =~ s{[_]$}{};
    $old_content =~ s{[_]+}{_}g;

    my $new_content = ':2<' . $old_content . '>';

    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::BasicTypes::Integers::FormatBinaryLiterals - Format 0b0101 properly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6> distribution.


=head1 DESCRIPTION

Perl6 binary literals have the format ':2<01_01_01_01>'. Perl6 enforces the rule that separators must occur between digits, and only one separator character at a time:

  0b01        -> :2<01>
  0b0101      -> :2<0101>
  0b010_10    -> :2<010_10>
  0b_010__10_ -> :2<010_10>

Transforms binary numbers outside of comments, heredocs, strings and POD.

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
