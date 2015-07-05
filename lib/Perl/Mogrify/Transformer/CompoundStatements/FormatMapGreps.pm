package Perl::Mogrify::Transformer::CompoundStatements::FormatMapGreps;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'given()' to 'given ()'};
Readonly::Scalar my $EXPL =>
    q{unless() needs whitespace in order to not be interpreted as a function call};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Statement' }

#-----------------------------------------------------------------------------

sub _make_a_block {
    # XXX Flaw in PPI: Cannot simply create PPI::Structure::* with ->new().
    # See https://rt.cpan.org/Public/Bug/Display.html?id=31564
    my $new_block = PPI::Structure::Block->new(
        PPI::Token::Structure->new('{'),
    ) or die;
    $new_block->{finish} = PPI::Token::Structure->new('}');

    return $new_block;
}

sub transform {
    my ($self, $elem, $doc) = @_;

    my $token = $elem->first_element;
    my $content = $token->content;
    return unless $content eq 'map' or
                  $content eq 'grep';
    return if $elem->child(3)->content eq ',';

    if ( $elem->child(2)->isa('PPI::Structure') and
         $elem->child(2)->start eq '{' and
         $elem->child(2)->finish eq '}' ) {
        my $comma = PPI::Token::Operator->new(',');
        $elem->child(2)->insert_after( $comma );
    }
    else {
        my $next_ssib = $elem->child(2);
        return if $next_ssib->isa('PPI::Structure::Block');

        # Can't use find() here because we need to search *forward* from $word,
        # not *down* within $word.

        my $last_sib = $next_ssib; # Can't be a comma, since `map ,` is invalid
        my @elements_to_move = $last_sib;
        while ( $last_sib = $last_sib->next_sibling ) {
            last if $last_sib->isa('PPI::Token::Operator')
                and $last_sib->content eq ',';
            push @elements_to_move, $last_sib;
        }
        return unless $last_sib;

        my $new_block = _make_a_block();
        $next_ssib->insert_before($new_block) or die;

        my $s = PPI::Statement->new();
        $_->remove          or die for @elements_to_move;
        $s->add_element($_) or die for @elements_to_move;

        $new_block->add_element($s)
            or die;
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::CompoundStatements::FormatMapGreps - Format given()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 unifies C<map{}> and C<grep{}> with the rest of the function calls, in that the first argument must be a block, and the arguments must be separated with commas. This transformer adds the block where needed, and inserts the comma as required:

  map {$_++} @x; --> map {$_++}, @x;
  map /x/ @x; --> map {/x/}, @x;
  grep {$_++} @x; --> grep {$_++}, @x;
  grep /x/ @x; --> grep {/x/}, @x;

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
