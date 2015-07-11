package Perl::Mogrify::Transformer::CompoundStatements::SwapForArguments;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_statement_compound };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'if()' to 'if ()'};
Readonly::Scalar my $EXPL =>
    q{if(), elsif() and unless() need whitespace in order to not be interpreted as function calls};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }

#-----------------------------------------------------------------------------

my %map = (
    for     => 1,
    foreach => 1,
);

my %scope_map = (
    my => 1,
    local => 1,
    our => 1
);

sub applies_to           {
    return sub {
        is_ppi_statement_compound($_[1], %map)
    }
}

#-----------------------------------------------------------------------------

#
# Just to help others keep track of what goes on here:
#
# The original statement
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0     1     2     3     4     5     6     7     8     # count by child()
#    \0           1           2           3           4     # count by schild
#     +-----+-----+-----+-----+-----+-----+-----+-----+
#     |     |     |     |     |     |     |     |     |
#     for  [' '   my]   ' '   $x    ' '   (@x)  ' '   {...}
#
# After removing the optional ' my' (not forgetting the whitespace)
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0     1     2     3     4     5     6     # count by child()
#    \0           1           2           3     # count by schild()
#     +-----+-----+-----+-----+-----+-----+
#     |     |     |     |     |     |     |
#     for   ' '   $x    ' '   (@x)  ' '   {...}
#
# After stashing the optional whitespace:
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0     1     2     3     4     5     # count by child()
#    \0     1           2           3     # count by schild()
#     +-----+-----+-----+-----+-----+
#     |     |     |     |     |     |
#     for   $x    ' '   (@x)  ' '   {...}
#
# After stashing the loop variable:
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0     1     2     3     4     # count by child()
#    \0           1           2     # count by schild()
#     +-----+-----+-----+-----+
#     |     |     |     |     |
#     for   ' '   (@x)  ' '   {...}
 
sub transform {
    my ($self, $elem, $doc) = @_;

    if ( $scope_map{$elem->schild(1)->content} ) {
        if ( $elem->child(1)->isa('PPI::Token::Whitespace') ) {
            $elem->child(1)->remove;
        }
   
        $elem->schild(1)->remove;
    }

    my $whitespace;
    if ( $elem->child(1)->isa('PPI::Token::WHitespace') ) {
        $whitespace = $elem->child(1)->clone;
        $elem->child(1)->remove;
    }
    my $variable = $elem->child(1)->clone;
    $elem->child(1)->remove;

#use YAML;warn Dump $elem;

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::CompoundStatements::SwapForArguments - Swap C<for my $x ( @x ) { }> --> C<<for ( @x ) -> $x { }>>


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 formats C<for my $x (@x) { }> as C<<for (@a) -> $x>>:

  for $x (@x) { } --> for (@x) -> $x { }
  for my $x (@x) { } --> for (@x) -> $x { }

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
