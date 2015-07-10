package Perl::Mogrify::Transformer::CompoundStatements::FormatMapGreps;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_token_word };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'given()' to 'given ()'};
Readonly::Scalar my $EXPL =>
    q{unless() needs whitespace in order to not be interpreted as a function call};

#-----------------------------------------------------------------------------

my %map = (
    map  => 1,
    grep => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1], %map)
    }
}

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
    my $token = $elem->snext_sibling;

    if ( $token->isa('PPI::Structure::Block') and
         $token->start eq '{' and
         $token->finish eq '}' ) {
        return if $token->snext_sibling->isa('PPI::Token::Operator') and
                  $token->snext_sibling->content eq ',';
        my $comma = PPI::Token::Operator->new(',');
        $token->insert_after( $comma );
    }
    else {
        my $point = $token;

        my $new_block = _make_a_block();
        my $new_statement = PPI::Statement->new;
        $new_block->add_element($new_statement);

        while ( $token and $token->next_sibling ) {
            last if $token->content eq ',';
            $new_statement->add_element($token->clone);
            $token = $token->next_sibling;
        }

        $point->insert_before($new_block);
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::CompoundStatements::FormatMapGreps - Format map{}, grep{}


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
