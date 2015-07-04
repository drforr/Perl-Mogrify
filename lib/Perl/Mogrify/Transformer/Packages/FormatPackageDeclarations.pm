package Perl::Mogrify::Transformer::Packages::FormatPackageDeclarations;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{'package' is now 'class'};
Readonly::Scalar my $EXPL =>
    q{Replace 'package Foo;' with 'unit class Foo;'};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    my $modified;

    my $tokens = $doc->find('PPI::Statement::Package');
    if ( $tokens ) {
        #
        # 'package Foo;' --> 'unit class Foo;'
        # 'package Foo { ... }' --> 'class Foo { ... }'
        #
        for my $package ( @{ $tokens } ) {
            $modified = 1;
            if ( $package->child(3)->isa('PPI::Token::Structure') and
                 $package->child(3)->content eq ';' ) {
                $package->first_element->set_content('class');
                $package->first_element->insert_before(
                    PPI::Token::Whitespace->new(' ')
                );
                $package->first_element->insert_before(
                    PPI::Token::Word->new('unit')
                );
            }
            else {
                $package->first_element->set_content('class');
            }
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $modified;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Packages::FormatPackageDeclarations - Format 'package Foo;' declarations


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

The Perl6 equivalent of a Perl5 package is 'class'. Older Perl5 source uses C<package Foo;> while some more modern source uses C<package Foo { .. }> to delineate package boundaries. This enforcer formats both case correctly:

  package Foo; --> unit class Foo;
  package Foo { ... } --> class Foo { ... }

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
