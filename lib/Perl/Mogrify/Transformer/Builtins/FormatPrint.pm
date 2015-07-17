package Perl::Mogrify::Transformer::Builtins::FormatPrint;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_token_word make_ppi_structure_list };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Format 'print FOO $text;' to 'FOO.print($text)'};
Readonly::Scalar my $EXPL => q{Format 'print FOO $text;' to 'FOO.print($text)'};

#-----------------------------------------------------------------------------

my %map = (
    print => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1], %map)
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
    my $elem = shift;
    return 1 if $elem->isa('PPI::Token::Structure') and
                $elem->content eq ';';
    return 1 if $elem->isa('PPI::Token::Word') and
                exists $postfix_modifier{$elem->content};
    return 1 if $elem->isa('PPI::Token::Operator') and
                exists $operator{$elem->content};
    return;
}

sub _is_almost_end_of_print_expression {
    my $elem = shift;
    return 1 if _is_end_of_print_expression($elem) or
                $elem->isa('PPI::Token::Whitespace') and
                _is_end_of_print_expression($elem->snext_sibling);
    return;
}

sub transform {
    my ($self, $elem, $doc) = @_;

    my $token = $elem->snext_sibling->snext_sibling;

    my $point = $token;

    my $new_list = make_ppi_structure_list;
    my $new_statement = PPI::Statement->new;
    $new_list->add_element($new_statement);

    while ( $token and $token->next_sibling ) {
        last if _is_almost_end_of_print_expression($token);
        $new_statement->add_element($token->clone);
        $token = $token->next_sibling;
    }

    $point->insert_before($new_list);
    while ( $point and
            not _is_almost_end_of_print_expression($point) ) {
        my $temp = $point->next_sibling;
        $point->remove;
        $point = $temp;
    }

    if ( $elem->next_sibling->isa('PPI::Token::Whitespace') ) {
        $elem->next_sibling->remove;
    }
    my $filehandle_variable = $elem->snext_sibling->clone;
    $elem->snext_sibling->remove;
    if ( $elem->next_sibling->isa('PPI::Token::Whitespace') ) {
        $elem->next_sibling->remove;
    }
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

Perl::Mogrify::Transformer::Builtins::FormatPrint - Format 'print $fh "expr"'


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
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