package Perl::Mogrify::Transformer::Operators::FormatUnaryOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_token_operator };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform unary operators to perl6 equivalents};
Readonly::Scalar my $EXPL =>
    q{Unary operators, notably '^' and '!', change names in Perl6};

#-----------------------------------------------------------------------------

my %map = (
    # '++', '--' are unchanged.
    # '!' is unchanged.
    # 'not' is unchanged.

    # '^', '!' are changed.
    '^' => '+^',
    '!' => '?^',
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_token_operator($_[1], '?' => 1 )
    }
}

#-----------------------------------------------------------------------------

sub transform {
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

    my $old_content = $elem->content;

    $elem->set_content( $map{$old_content} );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Operators::FormatUnaryOperators - Transform '^', '!' &c to Perl6 equivalents


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Some unary operators in Perl5 have been renamed in Perl6. For instance, the various negations such as '~', '^' and '!' have been unified under '^', and the previous numeric, logical and Boolean contexts are now represented in the first character, so '!' is now '?^' to repreent Boolean ('?') negation ('^'):

  ~32 --> +^32
  !$x --> ?^$x

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
