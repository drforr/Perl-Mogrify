package Perl::ToPerl6::Transformer::CompoundStatements::AddWhitespace;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    is_ppi_statement_compound
    is_ppi_token_word
    insert_trailing_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'if()' to 'if ()'};
Readonly::Scalar my $EXPL =>
    q{if(), elsif() and unless() need whitespace in order to not be interpreted as function calls};

#-----------------------------------------------------------------------------

my %map = (
    if      => 1,
    elsif   => 1,
    unless  => 1,
    given   => 1,
    when    => 1,
    while   => 1,
    until   => 1,
    for     => 1,
    foreach => 1,
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        is_ppi_statement_compound($_[1], %map) or
        $_[1]->isa('PPI::Statement::Given') or
        $_[1]->isa('PPI::Statement::When')
    }
}

#-----------------------------------------------------------------------------

#
# Note to the reader:
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0     1     2     3     4 # count by child()
#    \0     1     2     3     4 # count by schild()
#     +-----+-----+-----+-----+
#     |     |     |     |     |
#     V     V     V     V     V
#     if    (...) {...} elsif (...)
#
# After insertion, the tree looks like this:
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0     1     2     3     4     5    6 # count by child()
#    \0           1     2     3          4 # count by schild()
#     +-----+-----+-----+-----+-----+----+
#     |     |     |     |     |     |    |
#     V     V     V     V     V     V    V
#     if    ' '   (...) {...} elsif ' '  (...)

sub transform {
    my ($self, $elem, $doc) = @_;

    for my $child ( $elem->schildren ) {
        next unless is_ppi_token_word($child, %map);
        insert_trailing_whitespace($child);
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::CompoundStatements::AddWhitespace - Add whitespace between conditionals 'if', 'unless' &c and '(...)'


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

While Perl6 conditionals allow parentheses, they need whitespace between the bareword C<if> and the opening parenthesis to avoid being interpreted as a function call:

  if(1) { } elsif(){} --> if (1) { } elsif(){}
  if (1) { } elsif(){} --> if (1) { } elsif(){}

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
