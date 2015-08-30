package Perl::ToPerl6::Utils::PPI;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< blessed readonly looks_like_number >;

use Exporter 'import';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    dscanf

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

    ppi_list_elements

    set_string

    make_ppi_structure_list
    make_ppi_structure_block

    build_ppi_structure_block_from
    build_ppi_structure_list_from

    remove_expression_remainder

    remove_trailing_whitespace
    insert_trailing_whitespace

    remove_leading_whitespace
    insert_leading_whitespace

    replace_remainder_with_block
    replace_remainder_with_list
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------
#
# List the conversion possibilities separately, for now.
# I don't think there's much call for fancy modifiers, but I'll keep it in mind.

my @conversions = sort { length($b) <=> length($a) } (
    'd', 'bd',  'od',  'xd',     # Decimals
    'f', 'ef',  'ff',            # Floating-point numbers
    'o',                         # Operator
    'r', 'mr', 'sr', 'tr',       # Regular expressions
    's', 'ds', 'ls', 'ss', 'is', # Strings
    'v', 'av', 'gv', 'hv', 'sv', # Variables
    'L',                         # List
    'P',                         # Generic PPI token
    'W',                         # Word
);
my $conversions_re = join '|', @conversions;
my %conversion_type = (
    d  => 'PPI::Token::Number',
    bd => 'PPI::Token::Number::Binary',
    od => 'PPI::Token::Number::Octal',
    xd => 'PPI::Token::Number::Hex',
    f  => 'PPI::Token::Number::Float',
    ef => 'PPI::Token::Number::Exp',
    o  => 'PPI::Token::Operator',
    r  => 'PPI::Token::Regexp',
    mr => 'PPI::Token::Regexp::Match',
    sr => 'PPI::Token::Regexp::Substitute',
    tr => 'PPI::Token::Regexp::Transliterate',
    s  => 'PPI::Token::Quote::Single',
    ds => 'PPI::Token::Quote::Double',
    is => 'PPI::Token::Quote::Interpolate',
    ls => 'PPI::Token::Quote::Literal',
    ss => 'PPI::Token::Quote::Single',
    v  => 'PPI::Token::Symbol',
    av => 'PPI::Token::Symbol', # Must be smarter later.
    gv => 'PPI::Token::Symbol',
    hv => 'PPI::Token::Symbol',
    sv => 'PPI::Token::Symbol',
    L  => 'PPI::Structure::List',
    W  => 'PPI::Token::Word',
);

sub _retokenize {
    my (@token) = @_;

    # Regroup the '%%', '%v' and modified conversions.
    #
    my @final_token;
    for ( my $i = 0; $i < @token; $i++ ) {
        my $v = $token[$i];

        # If the token is a '%', then look ahead.
        #    If '%' is next, just tack it on to the existing '%' leaving '%%'.
        #    Otherwise, add whatever modifiers we can find from the next, and
        #        move on.
        #    Failing that, report that we've found a missing modifier.
        #
        if ( $v eq '%' ) {
            if ( $token[$i+1] eq '%' ) {
                push @final_token, $v . $token[$i+1];
                $i++;
            }
            elsif ( $token[$i+1] =~ s< ^ ($conversions_re) ><>x ) {
                my $conversion = $1;
                if ( $conversion eq 'P' ) {
                    $token[$i+1] =~ s< ^ \{ ([^\}]+) \} ><>x;
                    my $name = $1;
                    $name = 'PPI::' . $name unless $name =~ m< ^ PPI\:: >x;
                    $conversion .= $name;
                }
                push @final_token, $v . $conversion;
                $i++ if $token[$i+1] eq '';
            }
            else {
                die "Unknown conversion '" . $token[$i+1] . "'";
            }
        }
        else {
            push @final_token, $v;
        }
    }
    return @final_token;
}

sub dscanf {
    my ($format, $options) = @_;
    my @token = grep { $_ ne '' } split / ( \s+ | \% ) /x, $format;
    @token = _retokenize( @token );

    my @to_find;
    for my $token ( @token ) {
        next if $token =~ m< ^ \s+ $ >x;

        if ( $token eq '%%' ) {
            push @to_find, {
                type => 'PPI::Token::Operator',
                content => '%'
            };
        }
        elsif ( $token =~ s< ^ \% ><>x ) {
            if ( exists $conversion_type{$token} ) {
                push @to_find, {
                    type => $conversion_type{$token}
                };
            }
            elsif ( $token =~ s< ^ P (.+) $ ><>x ) {
                push @to_find, {
                    type => $1
                };
            }
            else {
die "Shouldn't happen, but a token type '$token' got here that we don't recognize, bailing.";
            }
        }
        else {
            if ( looks_like_number( $token ) ) {
                push @to_find, {
                    type => 'PPI::Token::Number',
                    content => $token
                };
            }
            elsif ( $token =~ / [^\w] /x ) {
                push @to_find, {
                    type => 'PPI::Token::Operator',
                    content => $token
                };
            }
            else {
                push @to_find, {
                    type => 'PPI::Token::Word',
                    content => $token
                };
            }
        }
    }

    return sub {
        my $elem = $_[1];

        for my $match ( @to_find ) {
            return 0 unless $elem->isa( $match->{type} );
            return 0 if $match->{content} and
                        $elem->content ne $match->{content};
            $elem = $elem->snext_sibling;
        }
        return 1;
    };
}

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

sub _ppi_list_elements {
    my ($elem) = @_;
    my @elements;
    for my $_elem ( $elem->schildren ) {
        if ( $_elem->isa('PPI::Token::Quote') ) {
            push @elements, $_elem->string;
        }
        elsif ( $_elem->isa('PPI::Structure::List') and
                $_elem->schildren ) {
            push @elements, _ppi_list_elements($_elem->schild(0));
        }
    }
    return @elements;
}

sub ppi_list_elements {
    my ($elem) = @_;
    return $elem->literal if $elem->isa('PPI::Token::QuoteLike::Words');

    if ( $elem->isa('PPI::Structure::List') and
         $elem->schild(0) and
         $elem->schild(0)->isa('PPI::Statement::Expression') ) {
        return _ppi_list_elements($elem->schild(0));
    }
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
        die "Unknown string delimiters! >$content<\n";
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

sub build_ppi_structure_block_from {
    my ($head, $terminator_test) = @_;

    my $new_block = make_ppi_structure_block;
    my $new_statement = PPI::Statement->new;

    while ( $head and $head->next_sibling ) {
        last if $terminator_test->(undef,$head);

        $new_statement->add_element($head->clone);
        $head = $head->next_sibling;
    }

    $new_block->add_element($new_statement);
    return $new_block;
}

#-----------------------------------------------------------------------------

sub build_ppi_structure_list_from {
    my ($head, $terminator_test) = @_;

    my $new_list = make_ppi_structure_list;
    my $new_statement = PPI::Statement->new;

    while ( $head and $head->next_sibling ) {
        last if $terminator_test->(undef,$head);

        $new_statement->add_element($head->clone);
        $head = $head->next_sibling;
    }

    $new_list->add_element($new_statement);
    return $new_list;
}

#-----------------------------------------------------------------------------

sub remove_expression_remainder {
    my ($head, $callback) = @_;
    while ( $head and not $callback->(undef,$head) ) {
        my $temp = $head->next_sibling;
        $head->remove;
        $head = $temp;
    }
}

#-----------------------------------------------------------------------------

sub remove_trailing_whitespace {
    my ($head) = @_;
    return unless $head->next_sibling;
    return unless $head->next_sibling->isa('PPI::Token::Whitespace');
    my $white = $head->next_sibling->clone;
    $head->next_sibling->remove;
    return $white;
}

#-----------------------------------------------------------------------------

sub insert_trailing_whitespace {
    my ($head, $optional_whitespace) = @_;
    $optional_whitespace = ' ' unless defined $optional_whitespace;
    return if $head->next_sibling and
              $head->next_sibling->isa('PPI::Token::Whitespace');
    $head->insert_after(
        PPI::Token::Whitespace->new($optional_whitespace)
    );
}

#-----------------------------------------------------------------------------

sub remove_leading_whitespace {
    my ($head) = @_;
    return unless $head->previous_sibling;
    return unless $head->previous_sibling->isa('PPI::Token::Whitespace');
    my $white = $head->previous_sibling->clone;
    $head->previous_sibling->remove;
    return $white;
}

#-----------------------------------------------------------------------------

sub insert_leading_whitespace {
    my ($head, $optional_whitespace) = @_;
    $optional_whitespace = ' ' unless defined $optional_whitespace;
    return if $head->previous_sibling and
              $head->previous_sibling->isa('PPI::Token::Whitespace');
    $head->insert_before(
        PPI::Token::Whitespace->new($optional_whitespace)
    );
} 
#-----------------------------------------------------------------------------

sub replace_remainder_with_block {
    my ($head, $callback) = @_;
    my $new_block = build_ppi_structure_block_from( $head, $callback );

    $head->insert_before($new_block);
    remove_expression_remainder( $head, $callback );
}

#-----------------------------------------------------------------------------

sub replace_remainder_with_list {
    my ($head, $callback) = @_;
    my $new_list = build_ppi_structure_list_from( $head, $callback );

    $head->insert_before($new_list);
    remove_expression_remainder( $head, $callback );
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

=item C<dscanf( $format_string, {options=>1} )>

    'a' -
    'b' -
    'c' -
    'd' - Specify an integer in an arbitrary base.
          If you want integers in a base other than decimal, add a modifier:
          'bd' - Binary integer
          'od' - Octal integer
          'xd' - Hexadecimal integer
    'e' -
    'f' - Specify a floating-point number.
          If you want floating-point numbers in exponential notation, add
          a modifier:
          'ef' - Exponential number
    'g' -
    'h' -
    'i' -
    'j' -
    'k' -
    'l' -
    'm' -
    'n' -
    'o' -
    'p' -
    'q' -
    'r' - Specify a regular expression.
          Note that this will match C</foo/>, C<s/foo/bar/>, C<y/a-m/n-z/>.
          If you want to match a specific regex type, then preface 'r' with:
          'mr' - Matching regular expression
          'sr' - Substitution regular expression
          'tr' - Transliterating regular expression
    's' - Specify a quoted string.
          This will match both C<'foo'> and C<qq qfooq> by default.
          If you want to match a specific string type, then preface 's' with:
          'ds' - Double-quoted string
          'ls' - Literal string type
          'ss' - Single-quoted string
          'is' - Interpolated string
    't' -
    'u' -
    'v' - Specify a Perl variable.
          If you want a specific type of variable, add one of these modifiers:
          'av' - Array variable
          'gv' - GLOB variable
          'hv' - Hash variable
          'sv' - Scalar variable
    'w' -
    'x' -
    'y' -
    'z' -

    'A' -
    'B' -
    'C' -
    'D' -
    'E' -
    'F' -
    'G' -
    'H' -
    'I' -
    'J' -
    'K' -
    'L' - A list.
    'M' -
    'N' -
    'O' -
    'P' - An explicit L<PPI> node type, C<'%P{Token::Word}'> for instance.
          You can prefix this with C<'PPI::'> but it's considered redundant.
    'Q' -
    'R' -
    'S' -
    'T' -
    'U' -
    'V' -
    'W' -
    'X' -
    'Y' -
    'Z' -

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
