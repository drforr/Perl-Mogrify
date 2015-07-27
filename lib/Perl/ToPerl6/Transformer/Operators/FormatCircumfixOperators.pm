package Perl::ToPerl6::Transformer::Operators::FormatCircumfixOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Binary operators should be formatted to their Perl6 equivalents};
Readonly::Scalar my $EXPL =>
    q{Format binary operators to their Perl6 equivalents};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Operator' }

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    # left     ->
    # nonassoc ++
    # nonassoc --
    # right    **
    # right    !
    # right    ~
    # right    \
    # right    +
    # right    -
    # left     =~
    # left     !~
    # left     *
    # left     /
    # left     %
    # left     x
    # left     +
    # left     -
    # left     .
    # left     <<
    # left     >>

    # nonassoc <
    # nonassoc >
    # nonassoc <=
    # nonassoc >=
    # nonassoc lt
    # nonassoc gt
    # nonassoc le
    # nonassoc ge
    # nonassoc ==
    # nonassoc !=
    # nonassoc <=>
    # nonassoc eq
    # nonassoc ne
    # nonassoc cmp
    # nonassoc ~~
    # left     &
    # left     |
    # left     ^
    # left     &&
    # left     ||
    # left     //
    # nonassoc ..
    # nonassoc ...
    # right    ?:
    # right    =
    # right    +=
    # right    -=
    # right    *= etc. goto last next redo dump
    # left     ,
    # left     =>

    # nonassoc list operators (rightward)
    # right    not
    # left     and
    # left     or
    # left     xor

#            my $old_content = $token->content;
# 
#            $token->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Operators::FormatCircumfixOperators - Format the {}, [], () operators


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

This module is unused, but may be used in the future.

=head1 CONFIGURATION

By default this Transformer does not alter '_' separators. Specify 0 for no separators, or a non-negative value if you want separators inserted every N digits:

    [BasicTypes::Rationals::FormatRationals]
    separators = 3

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
