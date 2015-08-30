package Perl::ToPerl6::Transformer::ModuleSpecific::Moose;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    insert_trailing_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform Moose attributes to Perl6};
Readonly::Scalar my $EXPL => q{Transform Moose attributes to Perl6};

#-----------------------------------------------------------------------------

sub run_before           { return 'Operators::FormatOperators' }
sub supported_parameters { return ()                           }
sub default_necessity    { return $NECESSITY_HIGHEST           }
sub default_themes       { return qw( tweaks )                 }
sub applies_to           { return 'PPI::Document'              }

#-----------------------------------------------------------------------------

sub ppi_is_fat_comma {
    $_[1]->isa('PPI::Token::Operator') and
    $_[1]->content eq '=>';
}

sub ppi_is_comma {
    $_[1] and
    $_[1]->isa('PPI::Token::Operator') and
    $_[1]->content eq ',';
}

sub moose_has_attribute {
    my ($elem) = @_;
    my $head = $elem;

    # In the string that follows, (( .. )) is not present in the code, but
    # represents the nesting of an expression inside a list that PPI does.

    # ----V
    # C<< has x => (( is => 'rw', isa => 'Int' )) >>
    #
    return unless $head->isa('PPI::Token::Word') and
                  $head->content eq 'has';
    $head = $head->snext_sibling;

    # --------V
    # C<< has x => (( is => 'rw', isa => 'Int' )) >>
    #
    return unless $head->isa('PPI::Token::Word');
    my $name = $head->content;
    $head = $head->snext_sibling;

    my $attributes;

    # ----------V
    # C<< has x => (( is => 'rw', isa => 'Int' )) >>
    #
    return unless ppi_is_fat_comma(undef,$head);
    $head = $head->snext_sibling;

    # -------------V
    # C<< has x => (( is => 'rw', isa => 'Int' )) >>
    #
    return unless $head->isa('PPI::Structure::List') and
                  $head->start->content eq '(';
    $head = $head->schild(0);

    # --------------V
    # C<< has x => (( is => 'rw', isa => 'Int' )) >>
    #
    return unless $head->isa('PPI::Statement::Expression');
    $head = $head->schild(0);

    while ( $head ) {
        # ----------------V
        # C<< has x => (( is => 'rw' )) >>
        #
        return unless $head->isa('PPI::Token::Word');
        my $curr_attribute = $head->content;
        $head = $head->snext_sibling;

        # -------------------V
        # C<< has x => (( is => 'rw' )) >>
        #
        return unless ppi_is_fat_comma(undef,$head);
        $head = $head->snext_sibling;

        # ----------------------V
        # C<< has x => (( is => 'rw' )) >>
        #
        $attributes->{$curr_attribute} = $head->string;
        $head = $head->snext_sibling;

        # --------------------------V
        # C<< has x => (( is => 'rw', isa => 'Int' )) >>
        #
        last unless ppi_is_comma(undef,$head);
        $head = $head->snext_sibling;
    }

    return ( $name, $attributes );
}

sub make_perl6_attribute {
    my ($name, $attributes) = @_;
    my $statement = PPI::Statement->new;
    $statement->add_element(
        PPI::Token::Word->new('has')
    );

    if ( $attributes->{isa} ) {
        $statement->add_element( PPI::Token::Whitespace->new(' ') );
        $statement->add_element(
            PPI::Token::Word->new( $attributes->{isa} )
        );
    }

    # Insert '$.<attribute name>'
    #
    $statement->add_element( PPI::Token::Whitespace->new(' ') );
    $statement->add_element(
        PPI::Token::Symbol->new('$.' . $name)
    );

    # If we have a read-write attribute flag, add that here.
    #
    if ( $attributes->{is} and $attributes->{is} eq 'rw' ) {
        $statement->add_element( PPI::Token::Whitespace->new(' ') );
        $statement->add_element(
            PPI::Token::Word->new('is')
        );
        $statement->add_element( PPI::Token::Whitespace->new(' ') );
        $statement->add_element(
            PPI::Token::Word->new('rw')
        );
    }
    $statement->add_element(
        PPI::Token::Structure->new(';')
    );
    $statement->add_element( PPI::Token::Whitespace->new("\n") );

    return $statement;
}

sub transform {
    my ($self, $elem, $doc) = @_;
    return unless $doc->find( sub {
        $_[1]->isa('PPI::Statement::Include') and
        $_[1]->schild(1)->content =~ m< ^ Moose >x
    } );

    my $attribute_keywords = $doc->find( sub {
        $_[1]->isa('PPI::Token::Word') and
        $_[1]->content eq 'has'
    } );

    for my $has ( @$attribute_keywords ) {
        my ( $name, $attributes ) = moose_has_attribute( $has );
        next unless $name;

        my $attribute = make_perl6_attribute( $name, $attributes );
        $has->parent->insert_after( $attribute );
        $has->parent->insert_after(
            PPI::Token::Whitespace->new("\n")
        );
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Instances::RewriteCreation - Indirect object notation no longer allowed.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 no longer supports Perl5-style indirect object notation.

  new Foo(); --> Foo.new();

Transforms 'new' statements outside of comments, heredocs, strings and POD.

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
