package Perl::Mogrify::Transformer::Operators::FormatBinaryOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Binary operators should be formatted to their Perl6 equivalents};
Readonly::Scalar my $EXPL =>
    q{Format binary operators to their Perl6 equivalents};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    return 1; # Can be anything.
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    # left     ->
    # right    **
    # right    and

    # right    +
    # right    -
    # left     =~
    # left     !~
    # left     *
    # left     /
    # left     %
    # left     x
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

    my %map = (
        # ',' is unchanged.
        # '+', '-', '*', '/', '%', '**' are unchanged.
        # '&&', '||', '^' are unchanged.
        # 'and', 'or', 'xor' are unchanged.
        # '==', '!=', '<', '>', '<=', '>=' are unchanged.
        # 'eq', 'ne', 'lt', 'gt', 'le', 'ge' are unchanged.

        # '<=>' behaves similarly.
        # 'cmp' is now named 'leg'.
        # '~~' is unchanged, but the semantics are wildly different.
        'cmp' => 'leg',

        # '&', '|', '^' are changed, and string semantics are different.
        '&'   => '+&',
        '|'   => '+|',
        '^'   => '+^',

        '<<' => '+<',
        '>>' => '+>',

        '.'  => '~',
    );

    my $operator = $doc->find('PPI::Token::Operator');
    if ( $operator and ref $operator ) {
        for my $token ( @{ $operator } ) {
            my $old_content = $token->content;
            if ( $old_content eq '=>' ) { # XXX This is a special case.
            }
            elsif ( $old_content eq 'x' ) { # XXX This is a special case.
            }
            elsif ( $old_content eq '..' ) { # XXX This is a special case.
                # List version is unchanged.
                # Scalar version is now 'ff'
$token->set_context('ff XXX');
            }
            elsif ( $old_content eq '...' ) { # XXX This is a special case.
                # List version is unchanged.
                # Scalar version is now 'fff'
$token->set_context('fff XXX');
            }
            else {
                $token->set_content( $map{$old_content} )
                    if $map{$old_content};
            }
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $operator and ref $operator;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Rationals::FormatRationals - Format 1.0, .1, 1. correctly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 floating-point values have the format '1.0' where a trailing digit is required. It also optionally adds separators every N digits before the decimal point.

  1.0 --> 1.0
  1.  --> 1.0 # Modified to perl6 standards
  .1  --> .1

This enforcer only operates on stand-alone floating point numbers.

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
