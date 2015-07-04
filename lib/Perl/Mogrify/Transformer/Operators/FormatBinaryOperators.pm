package Perl::Mogrify::Transformer::Operators::FormatBinaryOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform binary operators to perl6 equivalents};
Readonly::Scalar my $EXPL =>
    q{Binary operators, notably '->' and '.', change names in Perl6};

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

Perl::Mogrify::Transformer::Operators::FormatBinaryOperators - Transform binary operators to Perl6 equivalents


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Several Perl5 operators such as '->' and '.' have changed names, hopefully without changing precedence. Most binary operators transform in straightforward fashion, '->' changes to '.' and '.' changes to '~', but some, like 'x' are more complex and depend upon their context:

  1 + 1     --> 1 + 1
  1 % 7     --> 1 % 7
  Foo->[0]  --> Foo.[0]
  Foo->new  --> Foo.new
  'a' x 7   --> 'a' x 7
  ('a') x 7 --> 'a' xx 7

Transforms operators outside of comments, heredocs, strings and POD.

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
