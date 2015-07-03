package Perl::Mogrify::Enforcer::Operators::FormatUnaryOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

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

    # nonassoc ++
    # nonassoc --
    # right    !
    # right    ~
    # right    \
    # right    +
    # right    -
    # left     *
    # left     %

    # nonassoc ~~
    # left     &
    # right    *= etc. goto last next redo dump

    # nonassoc list operators (rightward)
    # right    not

    my %map = (
        # '++', '--' are unchanged.
        # '!' is unchanged.
        # 'not' is unchanged.

        # '^', '!' are changed.
        '^' => '+^',
        '!' => '?^',
    );

    my $operator = $doc->find('PPI::Token::Operator');
    if ( $operator and ref $operator ) {
        for my $token ( @{ $operator } ) {
#            my $old_content = $token->content;
# 
#            $token->set_content( $new_content );
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

Perl::Mogrify::Enforcer::BasicTypes::Rationals::FormatRationals - Format 1.0, .1, 1. correctly


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 floating-point values have the format '1.0' where a trailing digit is required. It also optionally adds separators every N digits before the decimal point.

  1.0 --> 1.0
  1.  --> 1.0 # Modified to perl6 standards
  .1  --> .1

This enforcer only operates on stand-alone floating point numbers.

=head1 CONFIGURATION

By default this Enforcer does not alter '_' separators. Specify 0 for no separators, or a non-negative value if you want separators inserted every N digits:

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
