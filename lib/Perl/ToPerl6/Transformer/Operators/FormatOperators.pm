package Perl::ToPerl6::Transformer::Operators::FormatOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    is_ppi_token_operator
    remove_trailing_whitespace
    insert_trailing_whitespace
    remove_leading_whitespace
    insert_leading_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform operators to perl6 equivalents};
Readonly::Scalar my $EXPL =>
    q{Operators, notably '->' and '!', change names in Perl6};

#-----------------------------------------------------------------------------

my %after = (
    and  => 1,
    or   => 1,
    xor  => 1,
    not  => 1,
    cmp  => 1,
    lt   => 1,
    gt   => 1,
    le   => 1,
    ge   => 1,
    eq   => 1,
    ne   => 1,
);

my %before = (
    '<'   => 1,
    '<='  => 1,
    '<=>' => 1,
);

my %mutate = (
    # From the unary operators:
    #
    # '++', '--' are unchanged.
    # '!' is unchanged.
    # 'not' is unchanged.

    # '^', '!' are changed.
    '^' => '+^',
    '!' => '?^',
    '~' => '+^',

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
    '&'   => '+&', '&=' => '+&=',
    '|'   => '+|', '|=' => '+|=',
    '^'   => '+^', '^=' => '+^=',

    '<<' => '+<', '<<=' => '+<=',
    '>>' => '+>', '>>=' => '+>=',

    '.'  => '~', '.=' => '~=',

    '->' => '.',

    '=~' => '~~',
    '!~' => '!~~',

    # And finally, the lone ternary operator:
    #
    '?' => '??',
    ':' => '!!',
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        is_ppi_token_operator($_[1], %mutate, %before, %after) or
        ( $_[1]->isa('PPI::Token::Label') and
          $_[1]->content =~ /\:$/ and
          $_[1]->sprevious_sibling and
          $_[1]->sprevious_sibling->isa('PPI::Token::Operator') and
          $_[1]->sprevious_sibling->content eq '?' )
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
    if ( $elem->isa('PPI::Token::Label') ) {
      my $old_content = $elem->content;

      $old_content =~ s< : $ ><!!>sx;

      $elem->set_content( $old_content );
    }

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

    $elem->set_content( $mutate{$old_content} ) if
        exists $mutate{$old_content};

    if ( $old_content eq '=>' ) { # XXX This is a special case.
    }
    elsif ( $old_content eq 'x' ) { # XXX This is a special case.
    }
    elsif ( $old_content eq '..' ) { # XXX This is a special case.
        # List version is unchanged.
        # Scalar version is now 'ff'
$elem->set_content('ff XXX');
    }
    elsif ( $old_content eq '...' ) { # XXX This is a special case.
        # List version is unchanged.
        # Scalar version is now 'fff'
$elem->set_content('fff XXX');
    }

    if ( $elem->content eq '.' ) {
        remove_trailing_whitespace($elem);
        remove_leading_whitespace($elem);
    }

    if ( $before{$elem->content} ) {
        insert_leading_whitespace($elem);
    }
    elsif ( $after{$elem->content} ) {
        insert_trailing_whitespace($elem);
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Operators::FormatOperators - Transform '->', '!" &c to their Perl6 equivalents


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Several operators in Perl5 have been renamed or repurposed in Perl6.  For instance, the various negations such as '~', '^' and '!' have been unified under '^', and the previous numeric, logical and Boolean contexts are now represented in the first character, so '!' is now '?^' to repreent Boolean ('?') negation ('^'):

  ~32 --> +^32
  !$x --> ?^$x
  1 ? 2 : 3 --> 1 ?? 2 !! 3

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
