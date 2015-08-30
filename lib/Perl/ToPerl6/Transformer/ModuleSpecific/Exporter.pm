package Perl::ToPerl6::Transformer::ModuleSpecific::Exporter;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    ppi_list_elements
    insert_trailing_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'new Foo()' to 'Foo->new()'};
Readonly::Scalar my $EXPL => q{Transform 'new Foo()' to 'Foo->new()'};

#-----------------------------------------------------------------------------

sub run_before           { return 'Operators::FormatOperators' }
sub supported_parameters { return ()                           }
sub default_necessity    { return $NECESSITY_HIGHEST           }
sub default_themes       { return qw( core )                   }
sub applies_to           { return 'PPI::Document'              }

#-----------------------------------------------------------------------------

sub ppi_rhs_list_values {
    my ($elem) = @_;
    my @values;
    if ( $elem->snext_sibling and
         $elem->snext_sibling->isa('PPI::Token::Operator') and
         $elem->snext_sibling->content eq '=' and
         $elem->snext_sibling->snext_sibling ) {
        push @values, ppi_list_elements(
            $elem->snext_sibling->snext_sibling
        );
    }
    return @values;
}

#
# All subs in @EXPORT will be marked with 'is export(:MANDATORY)'
# All subs in @EXPORT_OK will be marked with just 'is export'
# All subs in a tag of %EXPORT_TAGS will be marked with 'is export(:tag)'
#          (there's a default ':ALL' tag that may be useful)
#          ( 'is export(:a :b)' works for multiple tag names, I guess)

sub transform {
    my ($self, $elem, $doc) = @_;
    return unless $doc->find( sub {
        $_[1]->isa('PPI::Statement::Include') and
        $_[1]->schild(1)->content =~ m< ^ Exporter >x
    } );

    my $subroutine_tags = {};

    my $export = $doc->find( sub {
        $_[1]->isa('PPI::Token::Symbol') and
        $_[1]->content eq '@EXPORT'
    } );

    my $export_ok = $doc->find( sub {
        $_[1]->isa('PPI::Token::Symbol') and
        $_[1]->content eq '@EXPORT_OK'
    } );

    my $export_tags = $doc->find( sub {
        $_[1]->isa('PPI::Token::Symbol') and
        $_[1]->content eq '%EXPORT_TAGS'
    } );

    my $subs = $doc->find('PPI::Statement::Sub');

    if ( @$export ) {
        for my $_elem ( @$export ) {
            for ( ppi_rhs_list_values($_elem) ) {
                push @{ $subroutine_tags->{$_} }, 'MANDATORY'
            }
        }
    }
    #
    # XXX The code here assumes that @EXPORT and @EXPORT_OK are disjoint sets.
    #
    if ( @$export_ok ) {
        for my $_elem ( @$export_ok ) {
            for ( ppi_rhs_list_values($_elem) ) {
                $subroutine_tags->{$_} = 1;
            }
        }
    }

    for my $sub ( @$subs ) {
        next unless $sub->name;
        next unless exists $subroutine_tags->{$sub->name};
        my $export_tags = '';
        if ( ref $subroutine_tags->{$sub->name} ) {
            $export_tags = ' (' .
                           join( ', ', map { ":$_" }
                                      @{ $subroutine_tags->{$sub->name} } ) .
                           ')';
        }
        $sub->schild(1)->insert_after(
            PPI::Token::Attribute->new('is export' . $export_tags)
        );
        insert_trailing_whitespace($sub->schild(1));
    }

#    my $token = $elem->clone;
#    if ( $elem->snext_sibling->snext_sibling->isa('PPI::Token::Quote') ) {
#        my $new_list = make_ppi_structure_list;
#        my $new_statement = PPI::Statement->new;
#        $new_list->add_element($new_statement);
#        $new_statement->add_element(
#            $elem->snext_sibling->snext_sibling->clone
#        );
#
#        while ( $token and $token->next_sibling ) {
#            last if $token->content eq ',';
#            $new_statement->add_element($token->clone);
#            $token = $token->next_sibling;
#        }
#        $elem->snext_sibling->snext_sibling->remove;
#        $elem->snext_sibling->insert_after($new_list);
#        $elem->snext_sibling->snext_sibling->next_sibling->remove if
#            $elem->snext_sibling->snext_sibling->next_sibling->isa('PPI::Token::Whitespace');
#    }

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
