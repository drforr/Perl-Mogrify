package Perl::ToPerl6::Transformer::Subroutines::RemovePrototypes;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Remove prototypes from subroutines};
Readonly::Scalar my $EXPL => q{Remove prototypes from subroutines};

#-----------------------------------------------------------------------------

my %map = (
    sub => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Prototype') and
        ( exists $map{$_[1]->sprevious_sibling->content} or
          exists $map{$_[1]->sprevious_sibling->sprevious_sibling->content} )
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    $elem->remove unless $elem->content =~ /[a-zA-Z0-9]/;

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Subroutines::RemovePrototypes - Remove ($)-style prototypes on subroutines.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 now has proper function signatures, subroutine prototype are deprecated:

  sub foo($) { } --> sub foo { }
  sub foo($a) { } --> sub foo($a) { }

Transforms subroutines outside of comments, heredocs, strings and POD.

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
