package Perl::Mogrify::Transformer::FormatSpecialLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform '__END__' etc.};
Readonly::Scalar my $EXPL => q{__END__ and __DATA__ are now POD markers};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return 'PPI::Token::Separator',
           'PPI::Token::End'
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
    if ( $elem->isa('PPI::Token::Separator') ) {
        my $pod = PPI::Token::Word->new('=finish');
        $elem->insert_before($pod);
        $elem->remove;
    }
#    elsif ( $elem->isa('PPI::Token::Data') ) {
#    }
#
#        my $comma = PPI::Token::Operator->new(',');
#        $elem->child(2)->insert_after( $comma );
#    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::FormatSpecialLiterals - Format __END__, __DATA__


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

__END__ is replaced with the POD marker '=finish', and you can read beyond this boundary with the filehandle C<$*FINISH>:

  __END__ --> =finish

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