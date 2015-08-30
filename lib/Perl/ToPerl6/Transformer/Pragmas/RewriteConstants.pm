package Perl::ToPerl6::Transformer::Pragmas::RewriteConstants;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    insert_leading_whitespace
    remove_trailing_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform Readonly into constant};
Readonly::Scalar my $EXPL => q{Perl6 has real constants};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           { return 'PPI::Statement'   }

#-----------------------------------------------------------------------------

my %map = (
    'my'  => 1,
    'our' => 1
);

#
# Readonly our @foo => ('a', 'b') --> our constant @foo = ('a', 'b')
#
sub transform {
    my ($self, $elem, $doc) = @_;
    return unless $elem and $elem->first_element;

    my $head = $elem->first_element;
    my $current = $head;

    if ( $current->isa('PPI::Token::Word') and
         $current->content =~ m{^Readonly} ) {

        $current->set_content('constant');
        remove_trailing_whitespace($current);

        $current = $current->snext_sibling;

        if ( exists $map{$current->content} ) {
            $head->insert_before(
                PPI::Token::Word->new($current->content)
            );

            insert_leading_whitespace($head);

            my $temp = $current;
            $current = $current->snext_sibling;

            $temp->remove;
        }
        if ( $current->content =~ / ^ ( \$ | \@ ) /x ) {
            my $new_content = $current->content;
            $new_content =~ s< ^ ( \$ | \@ ) ><>x;
            $current->set_content($new_content);
        }

        $current = $current->snext_sibling;

        $current->set_content('=');
    }
    elsif ( $head->isa('PPI::Token::Word') and
            $head->content eq 'use' and
            $head->snext_sibling and
            $head->snext_sibling->isa('PPI::Token::Word') and
            $head->snext_sibling->content eq 'constant' ) {

        while ( $current->snext_sibling and $current->content ne '=>' ) {
            $current = $current->snext_sibling;
        }
        $current->set_content('=');

        remove_trailing_whitespace($head);
        $head->remove;
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::RewriteConstants - Transform Readonly and constant


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 has real constants, so we don't need modules or pragmas:

  use constant FOO => 1 --> constant $FOO = 1
  Readonly my @FOO => (1) --> my constant @FOO = (1)

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
