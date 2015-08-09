package Perl::ToPerl6::Transformer::Builtins::AddWhitespace;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_ppi_token_word };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform my(...) to my (...)};
Readonly::Scalar my $EXPL => q{Transform my(...) to my (...)};

#-----------------------------------------------------------------------------

my %map = (
    my => 1,
    our => 1,
    print => 1,
);

sub supported_parameters { return ()                }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1], %map)
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    if ( $elem->next_sibling and
         not $elem->next_sibling->isa('PPI::Token::Whitespace') ) {
        $elem->insert_after(
            PPI::Token::Whitespace->new(' ')
        );
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Buiiltins::AddWhitespace - Format my(), our(), print()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6> distribution.


=head1 DESCRIPTION

Perl6 requires whitespace after C<my>, C<our>, C<print> etc. in order to not confuse these builtins with methods:

  my() --> my ()
  our() --> our ()
  print() --> print ()

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
