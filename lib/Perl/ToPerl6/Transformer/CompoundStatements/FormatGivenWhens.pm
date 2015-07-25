package Perl::ToPerl6::Transformer::CompoundStatements::FormatGivenWhens;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'given()' to 'given ()'};
Readonly::Scalar my $EXPL =>
    q{unless() needs whitespace in order to not be interpreted as a function call};

#-----------------------------------------------------------------------------

my %map = (
    given => 1,
    when => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        ( $_[1]->isa('PPI::Statement::Given') or
          $_[1]->isa('PPI::Statement::When') ) and
        exists $map{$_[1]->first_element->content} and
        not $_[1]->first_element->next_sibling->isa('PPI::Token::Whitespace');
    }
}

#-----------------------------------------------------------------------------

#
# Note to the reader:
#
# PPI::Statement::{Given,When}
#  \
#   \ 0     1     2   # count by child()
#    \0     1     2   # count by schild()
#     +-----+-----+
#     |     |     |
#     given (...) {...}
#
# After insertion, the tree looks like this:
#
# PPI::Statement::{Given,When}
#  \
#   \ 0     1     2     3 # count by child()
#    \0           1     2 # count by schild()
#     +-----+-----+-----+
#     |     |     |     |
#     given ' '   (...) {...}

sub transform {
    my ($self, $elem, $doc) = @_;

    $elem->first_element->insert_after(
        PPI::Token::Whitespace->new(' ')
    );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::CompoundStatements::FormatGivenWhens - Format given(), when()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

While Perl6 conditionals allow parentheses, they need whitespace between the bareword C<given> and the opening parenthesis to avoid being interpreted as a function call:

  given(1) { }  --> given (1) { }
  when(1) { }   --> when (1) { }
  given (1) { } --> given (1) { }
  when (1) { }  --> when (1) { }

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
