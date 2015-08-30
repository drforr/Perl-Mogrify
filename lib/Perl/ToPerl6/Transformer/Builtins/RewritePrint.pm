package Perl::ToPerl6::Transformer::Builtins::RewritePrint;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    is_ppi_token_word
    remove_trailing_whitespace
    replace_remainder_with_list
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Format 'print FOO $text;' to 'FOO.print($text)'};
Readonly::Scalar my $EXPL => q{Format 'print FOO $text;' to 'FOO.print($text)'};

#-----------------------------------------------------------------------------

my %map = (
    print => 1
);

#-----------------------------------------------------------------------------

# Our first usage of the topological sorting.
#
# The change 'print FOO "stuff"' --> 'FOO.print("stuff")' rewrites the Perl5
# code to Perl6, so it has to be run *after* the Perl5-Perl6 operator
# conversion has taken place.
#
# It might even be better to rephrase this in terms of:
#
#   "Run this test only after resetting the content of PPI::Token::Operators"
#   but that feel dangerous and fragile.
#

sub run_after            { return 'Operators::FormatOperators' }
sub supported_parameters { return ()                           }
sub default_necessity    { return $NECESSITY_HIGHEST           }
sub default_themes       { return qw( core )                   }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1], %map) and
        not ( $_[1]->snext_sibling
                   ->snext_sibling->isa('PPI::Token::Operator') and
              $_[1]->snext_sibling
                   ->snext_sibling->content eq ',' )
    }
}

#-----------------------------------------------------------------------------

my %postfix_modifier = (
    if      => 1,
    unless  => 1,
    while   => 1,
    until   => 1,
    for     => 1,
    foreach => 1
);

my %operator = (
    and  => 1,
    or   => 1,
    xor  => 1,
    '&&' => 1,
    '||' => 1,
    '^^' => 1
);

sub _is_end_of_print_expression {
    ( $_[1]->isa('PPI::Token::Structure') and
      $_[1]->content eq ';' ) or
    ( $_[1]->isa('PPI::Token::Word') and
      exists $postfix_modifier{$_[1]->content} ) or
    ( $_[1]->isa('PPI::Token::Operator') and
      exists $operator{$_[1]->content} )
}

sub transform {
    my ($self, $elem, $doc) = @_;
    return unless $elem->snext_sibling and
                  $elem->snext_sibling->snext_sibling;

    my $token = $elem->snext_sibling->snext_sibling;
    replace_remainder_with_list(
        $token, sub {
            _is_end_of_print_expression(@_) or
            $_[1]->isa('PPI::Token::Whitespace') and
            _is_end_of_print_expression(undef,$_[1]->snext_sibling);
        }
    );

    remove_trailing_whitespace($elem);

    my $filehandle_variable = $elem->snext_sibling->clone;
    $elem->snext_sibling->remove;

    remove_trailing_whitespace($elem);

    $elem->insert_before($filehandle_variable);
    $elem->insert_before(
        PPI::Token::Operator->new('.')
    );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Builtins::RewritePrint - Format 'print $fh "expr"'


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 now uses a C<print> method on filehandles as opposed to the old C<print $fh>:

  print $fh $x --> $fh.print($x)

Transforms variables outside of comments, heredocs, strings and POD.

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
