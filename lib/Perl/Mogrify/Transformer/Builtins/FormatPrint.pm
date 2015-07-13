package Perl::Mogrify::Transformer::Builtins::FormatPrint;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_statement };

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
        is_ppi_statement($_[1],%map) and
        not ( $_[1]->schild(2) and
              $_[1]->schild(2)->isa('PPI::Token::Operator') and
              $_[1]->schild(2)->content eq ',' )
    }
}

#-----------------------------------------------------------------------------

sub _make_a_list {
    # XXX Flaw in PPI: Cannot simply create PPI::Structure::* with ->new().
    # See https://rt.cpan.org/Public/Bug/Display.html?id=31564
    my $new_list = PPI::Structure::List->new(
        PPI::Token::Structure->new('('),
    ) or die;
    $new_list->{finish} = PPI::Token::Structure->new(')');

    return $new_list;
}

sub transform {
    my ($self, $elem, $doc) = @_;

    my $token = $elem->schild(2);

    my $point = $token;

    my $new_list = _make_a_list();
    my $new_statement = PPI::Statement->new;
    $new_list->add_element($new_statement);

    while ( $token and $token->next_sibling ) {
        last if $token->content eq ';' or
                $token->content eq 'if' or
                $token->content eq 'unless';
        $new_statement->add_element($token->clone);
        $token = $token->next_sibling;
    }

    $point->insert_before($new_list);
    while ( $point and
            not ( $point->isa('PPI::Token::Word') and
                  $point->content eq 'if' ) and
            not ( $point->isa('PPI::Token::Word') and
                  $point->content eq 'unless' ) and
            not ( $point->isa('PPI::Token::Structure') and
                  $point->content eq ';' ) ) {
        my $temp = $point->next_sibling;
        $point->remove;
        $point = $temp;
    }

    if ( $elem->schild(0)->next_sibling->isa('PPI::Token::Whitespace') ) {
        $elem->schild(0)->next_sibling->remove;
    }
    my $filehandle_variable = $elem->schild(1)->clone;
    $elem->schild(1)->remove;
    if ( $elem->schild(0)->next_sibling->isa('PPI::Token::Whitespace') ) {
        $elem->schild(0)->next_sibling->remove;
    }
    $elem->schild(0)->insert_before(
        PPI::Token::Operator->new('.')
    );
    $elem->schild(0)->insert_before($filehandle_variable);

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Variables::FormatSigils - Give variables their proper sigils.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 uses the sigil type as the data type now, and this is probably the most common operation people will want to do to their file. This transformer doesn't alter hash keys or array indices, those are left to transformers down the line:

  @foo = () --> @foo = ()
  $foo[1] --> @foo[1]
  %foo = () --> %foo = ()
  $foo{a} --> %foo{a} # Not %foo<a> or %foo{'a'} yet.

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
