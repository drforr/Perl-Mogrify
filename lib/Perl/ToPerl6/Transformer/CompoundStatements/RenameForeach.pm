package Perl::ToPerl6::Transformer::CompoundStatements::RenameForeach;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_ppi_statement_compound };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'foreach' to 'for'};
Readonly::Scalar my $EXPL => q{foreach() is now nmaed for()};

#-----------------------------------------------------------------------------

my %map = (
    foreach => 'for',
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_statement_compound($_[1], %map)
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->schild(0)->content;

    $elem->schild(0)->set_content($map{$old_content});

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::CompoundStatements::RenameForeach - Rename 'foreach' to 'for'


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 no longer uses 'foreach':

  foreach(1) { } --> for(1) { }

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
