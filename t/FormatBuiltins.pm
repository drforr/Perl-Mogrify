package Perl::Mogrify::Transformer::FormatBuiltins;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

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

sub _make_a_method {
    # XXX Flaw in PPI: Cannot simply create PPI::Structure::* with ->new().
    # See https://rt.cpan.org/Public/Bug/Display.html?id=31564
    my $new_block = PPI::Structure::Block->new(
        PPI::Token::Structure->new('('),
    ) or die;
    $new_block->{finish} = PPI::Token::Structure->new('(');

    return $new_block;
}

my %map = (
    print => 1
);

#
# print $fh 1 --> $fh.print(1)
#
sub transform {
    my ($self, $elem, $doc) = @_;
###     my $head = $elem->first_element;
###     return unless exists $map{$head->content};
### 
###     my $current = $head;
### 
###     if ( $current->content eq 'print' ) {
###         $current = $current->next_sibling;
### 
###         my $print = PPI::Token::Word->new('print');
### 
###         my $last_sib = $current;
###         my @elements_to_move = $elem;
###         while ( $last_sib = $last_sib->next_sibling ) {
###             last if $last_sib->isa('PPI::Token::Operator')
###                 and $last_sib->content eq ',';
###             push @elements_to_move, $last_sib;
###         }
### #        return unless $last_sib;
### 
###         my $new_block = _make_a_method();
###         $head->insert_before($new_block);
### 
### #        my $block = $elem->snext_sibling;
### # 
### #        sif ( !$block->isa('PPI::Structure::Block') ) {
### #            # Can't use find() here because we need to search *forward* from $word,
### #            # not *down* within $word.
### # 
### #            my $last_sib = $block; # Can't be a comma, since `map ,` is invalid
### #            my @elements_to_move = $block;
### #            while ( $last_sib = $last_sib->next_sibling ) {
### #                last if $last_sib->isa('PPI::Token::Operator')
### #                    and $last_sib->content eq ',';
### #                push @elements_to_move, $last_sib;
### #            }
### #            return unless $last_sib;
### # 
### #            my $new_block = _make_a_block();
### #            $block->insert_before($new_block) or die;
### # 
### #            my $s = PPI::Statement->new();
### #            $_->remove          or die for @elements_to_move;
### #            $s->add_element($_) or die for @elements_to_move;
### # 
### #            $new_block->add_element($s)
### #                or die;
### #        }
### 
###         $current->insert_after($print);
###     
### #        $head->remove;
###     }

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
