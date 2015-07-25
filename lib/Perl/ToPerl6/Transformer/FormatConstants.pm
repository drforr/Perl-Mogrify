package Perl::ToPerl6::Transformer::FormatConstants;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform Readonly into constant};
Readonly::Scalar my $EXPL => q{Perl6 has real constants};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Statement' }

#-----------------------------------------------------------------------------

my %map = (
    'my' => 1,
    'our' => 1
);

#
# Readonly our @foo => ('a', 'b') --> our constant @foo = ('a', 'b')
#
sub transform {
    my ($self, $elem, $doc) = @_;
    my $head = $elem->first_element;
    my $current = $head;

    if ( $current and
         $current->isa('PPI::Token::Word') and
         $current->content =~ m{^Readonly} ) {

        $current->set_content('constant');

        $current = $current->snext_sibling;

        if ( exists $map{$current->content} ) {
            my $scope = PPI::Token::Word->new($current->content);

            $head->insert_before($scope);

            my $whitespace = PPI::Token::Whitespace->new(' ');

            $head->insert_before($whitespace);

            my $temp = $current;

            $current = $current->snext_sibling;

            $temp->remove;
        }

        $current = $current->snext_sibling;

        $current->set_content('=');
    }
    elsif ( $head and
            $head->isa('PPI::Token::Word') and
            $head->content eq 'use' and
            $head->snext_sibling->isa('PPI::Token::Word') and
            $head->snext_sibling->content eq 'constant' ) {

        my $new_content = $head->snext_sibling->content;

        $current = $current->snext_sibling;

        $head->remove;

        $current = $current->snext_sibling;

        $current->set_content( '$' . $current->content );

        $current->snext_sibling->set_content('=');

        $current = $current->snext_sibling;
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::FormatConstants - Transform Readonly and constant


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
