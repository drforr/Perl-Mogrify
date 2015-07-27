package Perl::ToPerl6::Utils::PPI;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< blessed readonly looks_like_number >;

use Exporter 'import';

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    is_ppi_expression_or_generic_statement
    is_ppi_generic_statement
    is_ppi_statement_subclass
    is_ppi_simple_statement
    is_ppi_constant_element

    is_package_boundary

    is_module_name
    is_version_number
    is_pragma

    is_ppi_token_word
    is_ppi_token_operator
    is_ppi_statement
    is_ppi_statement_compound

    is_ppi_token_quotelike_words_like

    set_string

    make_ppi_structure_list
    make_ppi_structure_block
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub is_ppi_token_word {
    my ($elem, %map) = @_;
    $elem and
    $elem->isa('PPI::Token::Word') and
    exists $map{$elem->content};
}

#-----------------------------------------------------------------------------

sub is_ppi_token_operator {
    my ($elem, %map) = @_;
    $elem and
    $elem->isa('PPI::Token::Operator') and
    exists $map{$elem->content};
}

#-----------------------------------------------------------------------------

sub is_ppi_statement {
    my ($elem, %map) = @_;
    $elem and
    $elem->isa('PPI::Statement') and
    exists $map{$elem->first_element->content};
}

#-----------------------------------------------------------------------------

sub is_ppi_statement_compound {
    my ($elem, %map) = @_;
    $elem and
    $elem->isa('PPI::Statement::Compound') and
    exists $map{$elem->first_element->content};
}

#-----------------------------------------------------------------------------

sub is_ppi_token_quotelike_words_like {
    my ($elem, $qr) = @_;
    $elem and
    $elem->isa('PPI::Token::QuoteLike::Words') and
    $elem->content =~ $qr
}

#-----------------------------------------------------------------------------

sub is_module_name {
    my $element = shift;

    return if not $element;

    return unless $element->isa('PPI::Token::Word');
    my $content = $element->content;

    return if looks_like_number($content);
    return if $content =~ /^v\d+/;

    return 1;
}

#-----------------------------------------------------------------------------

sub is_version_number {
    my $element = shift;

    return if not $element;

    return unless $element->isa('PPI::Token::Word') or
                  $element->isa('PPI::Token::Number::Version') or
                  $element->isa('PPI::Token::Number::Float');
    my $content = $element->content;

    return 1 if looks_like_number($content);
    return 1 if $content =~ /^v\d+/;

    return;
}

#-----------------------------------------------------------------------------

sub is_pragma {
    my $element = shift;

    return if not $element;

    return unless $element->isa('PPI::Token::Word');
    my $content = $element->content;

    my %pragma = (
        strict => 1,
        warnings => 1,
        autodie => 1,
        base => 1,
        parent => 1,
        bigint => 1,
        bignum => 1,
	bigrat => 1,
	constant => 1,
	mro => 1,
	encoding => 1,
	integer => 1,
	lib => 1,
	mro => 1,
	utf8 => 1,
	vars => 1,
    );

    return 1 if exists $pragma{$content};

    return;
}

#-----------------------------------------------------------------------------

sub set_string {
    my ($elem, $string) = @_;
    $string = '' unless $string;

    my $content = $elem->content;
    if ($content =~ m/ ^ ['"] /x ) {
        substr($content, 1, -1) = $string;
    }
    elsif ($content =~ m/^qq ./ ) {
        substr($content, 4, -1) = $string;
    }
    elsif ($content =~ m/^qq./ ) {
        substr($content, 3, -1) = $string;
    }
    elsif ($content =~ m/^q ./ ) {
        substr($content, 3, -1) = $string;
    }
    elsif ($content =~ m/^q./ ) {
        substr($content, 2, -1) = $string;
    }
    else {
        die "Unknown string delimiters!\n";
    }
    $elem->set_content( $content );
}

#-----------------------------------------------------------------------------

sub make_ppi_structure_block {
    my $new_list = PPI::Structure::Block->new(
        PPI::Token::Structure->new('{'),
    );
    $new_list->{finish} = PPI::Token::Structure->new('}');

    return $new_list;
}

#-----------------------------------------------------------------------------

sub make_ppi_structure_list {
    my $new_list = PPI::Structure::List->new(
        PPI::Token::Structure->new('('),
    );
    $new_list->{finish} = PPI::Token::Structure->new(')');

    return $new_list;
}

#-----------------------------------------------------------------------------

sub is_ppi_generic_statement {
    my $element = shift;

    my $element_class = blessed($element);

    return if not $element_class;
    return if not $element->isa('PPI::Statement');

    return $element_class eq 'PPI::Statement';
}

#-----------------------------------------------------------------------------

sub is_ppi_statement_subclass {
    my $element = shift;

    my $element_class = blessed($element);

    return if not $element_class;
    return if not $element->isa('PPI::Statement');

    return $element_class ne 'PPI::Statement';
}

#-----------------------------------------------------------------------------

# Can not use hashify() here because Perl::Critic::Utils already depends on
# this module.
Readonly::Hash my %SIMPLE_STATEMENT_CLASS => map { $_ => 1 } qw<
    PPI::Statement
    PPI::Statement::Break
    PPI::Statement::Include
    PPI::Statement::Null
    PPI::Statement::Package
    PPI::Statement::Variable
>;

sub is_ppi_simple_statement {
    my $element = shift or return;

    my $element_class = blessed( $element ) or return;

    return $SIMPLE_STATEMENT_CLASS{ $element_class };
}

#-----------------------------------------------------------------------------

sub is_ppi_constant_element {
    my $element = shift or return;

    blessed( $element ) or return;

    # TODO implement here documents once PPI::Token::HereDoc grows the
    # necessary PPI::Token::Quote interface.
    return
            $element->isa( 'PPI::Token::Number' )
        ||  $element->isa( 'PPI::Token::Quote::Literal' )
        ||  $element->isa( 'PPI::Token::Quote::Single' )
        ||  $element->isa( 'PPI::Token::QuoteLike::Words' )
        ||  (
                $element->isa( 'PPI::Token::Quote::Double' )
            ||  $element->isa( 'PPI::Token::Quote::Interpolate' ) )
            &&  $element->string() !~ m< (?: \A | [^\\] ) (?: \\\\)* [\$\@] >smx
        ;
}

#-----------------------------------------------------------------------------

sub is_package_boundary {
    my ($elem) = @_;
    return unless $elem;
    return 1 if $elem->isa('PPI::Statement::Package');
    return 1 if $elem->isa('PPI::Statement::End');
    return 1 if $elem->isa('PPI::Statement::Data');
    return 1 if $elem->isa('PPI::Token::Separator');
    return;
}

#-----------------------------------------------------------------------------

sub is_subroutine_declaration {
    my $element = shift;

    return if not $element;

    return 1 if $element->isa('PPI::Statement::Sub');

    if ( is_ppi_generic_statement($element) ) {
        my $first_element = $element->first_element();

        return 1 if
                $first_element
            and $first_element->isa('PPI::Token::Word')
            and $first_element->content() eq 'sub';
    }

    return;
}

#-----------------------------------------------------------------------------

sub is_in_subroutine {
    my ($element) = @_;

    return if not $element;
    return 1 if is_subroutine_declaration($element);

    while ( $element = $element->parent() ) {
        return 1 if is_subroutine_declaration($element);
    }

    return;
}

#-----------------------------------------------------------------------------

sub get_constant_name_element_from_declaring_statement {
    my ($element) = @_;

    warnings::warnif(
        'deprecated',
        'Perl::Critic::Utils::PPI::get_constant_name_element_from_declaring_statement() is deprecated. Use PPIx::Utilities::Statement::get_constant_name_elements_from_declaring_statement() instead.',
    );

    return if not $element;
    return if not $element->isa('PPI::Statement');

    if ( $element->isa('PPI::Statement::Include') ) {
        my $pragma;
        if ( $pragma = $element->pragma() and $pragma eq 'constant' ) {
            return _constant_name_from_constant_pragma($element);
        }
    }
    elsif (
            is_ppi_generic_statement($element)
        and $element->schild(0)->content() =~ m< \A Readonly \b >xms
    ) {
        return $element->schild(2);
    }

    return;
}

sub _constant_name_from_constant_pragma {
    my ($include) = @_;

    my @arguments = $include->arguments() or return;

    my $follower = $arguments[0];
    return if not defined $follower;

    return $follower;
}

#-----------------------------------------------------------------------------

sub get_next_element_in_same_simple_statement {
    my $element = shift or return;

    while ( $element and (
            not is_ppi_simple_statement( $element )
            or $element->parent()
            and $element->parent()->isa( 'PPI::Structure::List' ) ) ) {
        my $next;
        $next = $element->snext_sibling() and return $next;
        $element = $element->parent();
    }
    return;

}

#-----------------------------------------------------------------------------

sub get_previous_module_used_on_same_line {
    my $element = shift or return;

    my ( $line ) = @{ $element->location() || []};

    while (not is_ppi_simple_statement( $element )) {
        $element = $element->parent() or return;
    }

    while ( $element = $element->sprevious_sibling() ) {
        ( @{ $element->location() || []} )[0] == $line or return;
        $element->isa( 'PPI::Statement::Include' )
            and return $element->schild( 1 );
    }

    return;
}

#-----------------------------------------------------------------------------

sub is_ppi_expression_or_generic_statement {
    my $element = shift;

    return if not $element;
    return if not $element->isa('PPI::Statement');
    return 1 if $element->isa('PPI::Statement::Expression');

    my $element_class = blessed($element);

    return if not $element_class;
    return $element_class eq 'PPI::Statement';
}
#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::Utils::PPI - Utility functions for dealing with PPI objects.


=head1 DESCRIPTION

Provides classification of L<PPI::Elements|PPI::Elements>.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<is_ppi_expression_or_generic_statement( $element )>

Answers whether the parameter is an expression or an undifferentiated
statement.  I.e. the parameter either is a
L<PPI::Statement::Expression|PPI::Statement::Expression> or the class
of the parameter is L<PPI::Statement|PPI::Statement> and not one of
its subclasses other than C<Expression>.


=item C<is_ppi_generic_statement( $element )>

Answers whether the parameter is an undifferentiated statement, i.e.
the parameter is a L<PPI::Statement|PPI::Statement> but not one of its
subclasses.


=item C<is_ppi_statement_subclass( $element )>

Answers whether the parameter is a specialized statement, i.e. the
parameter is a L<PPI::Statement|PPI::Statement> but the class of the
parameter is not L<PPI::Statement|PPI::Statement>.


=item C<is_ppi_simple_statement( $element )>

Answers whether the parameter represents a simple statement, i.e. whether the
parameter is a L<PPI::Statement|PPI::Statement>,
L<PPI::Statement::Break|PPI::Statement::Break>,
L<PPI::Statement::Include|PPI::Statement::Include>,
L<PPI::Statement::Null|PPI::Statement::Null>,
L<PPI::Statement::Package|PPI::Statement::Package>, or
L<PPI::Statement::Variable|PPI::Statement::Variable>.

=back

=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>

=head1 AUTHOR EMERITUS

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
