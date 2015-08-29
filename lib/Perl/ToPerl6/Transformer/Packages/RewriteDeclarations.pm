package Perl::ToPerl6::Transformer::Packages::RewriteDeclarations;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    is_ppi_token_word
    is_package_boundary
    make_ppi_structure_block
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'package' declaration into 'class'};
Readonly::Scalar my $EXPL => q{The Perl6 equivalent of packages are classes.};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           { return 'PPI::Document'    }

#-----------------------------------------------------------------------------

# Just make this a document-level processor for the time being.
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $ref = $doc->find('PPI::Statement::Package');
    if ( $ref and @{ $ref } ) {
        my @package = @{ $ref };
        for my $package ( @package ) {
            $package->schild(0)->set_content('unit class');

#            if ( $package->schild(2) and
#                 $package->schild(2)->isa('PPI::Token::Structure') and
#                 $package->schild(2)->content eq ';' ) {
#
#                my $new_block = make_ppi_structure_block;
#                my $new_statement = PPI::Statement->new;
#                $new_block->add_element($new_statement);
#         
#                my $token = $package->next_sibling;
#                while ( $token and $token->next_sibling ) {
#                    last if is_package_boundary($token);
#                    $new_statement->add_element($token->clone);
#                    $token = $token->next_sibling;
#                }
#         
#                my $point = $package->next_sibling;
#                while ( $point and
#                        not is_package_boundary($point) ) {
#                    my $temp = $point->next_sibling;
#                    $point->remove;
#                    $point = $temp;
#                }
#                $package->last_element->insert_before($new_block);
#            }
        }
        return $self->transformation( $DESC, $EXPL, $elem );
    }

    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Packages::RewriteDeclarations - Format 'package Foo;' declarations


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

The Perl6 equivalent of a Perl5 package is 'class'. Older Perl5 source uses C<package Foo;> while some more modern source uses C<package Foo { .. }> to delineate package boundaries:

  package Foo; --> class Foo { ... }
  package # ?
  Foo;         --> class\n# ?\nFoo { ... }
  package Foo { ... } --> class Foo { ... }

Other transformers will be responsible for ensuring that perl5 classes inherit correctly.

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
