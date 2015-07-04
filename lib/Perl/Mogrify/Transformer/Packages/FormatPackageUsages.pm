package Perl::Mogrify::Transformer::Packages::FormatPackageUsages;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_module_name is_pragma };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{'use Foo;' from perl5 code uses 'use Foo:from<Perl5>;'};
Readonly::Scalar my $EXPL =>
    q{'use Foo;' from perl5 code uses 'use Foo:from<Perl5>;'};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    my $modified;

    my $tokens = $doc->find('PPI::Statement::Include');
    if ( $tokens ) {
        #
        # 'use Foo;' --> 'use Foo:from<Perl5>;'
        # 'use Foo qw(a);' --> 'use Foo:from<Perl5> <a>;'
        #
        # Although this module only adjusts the 'Foo' bit.
        #
        for my $package ( @{ $tokens } ) {
            my $package_name = $package->child(2);
            next if is_pragma($package_name);
            next unless is_module_name($package_name);

            $modified = 1;
            my $old_content = $package_name;
            $old_content .= ':from<Perl5>';
            $package_name->set_content($old_content);
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

Perl::Mogrify::Transformer::Packages::FormatPackageUsages - Format 'use Foo;' to 'use Foo:from<Perl5>;'


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

This Transformer assumes that you have installed L<Inline::Perl5> in your Perl6 environment, as it uses the C<< :from<Perl5> >> adverb.

This Transformer assumes that you are porting existing Perl5 code to work on Perl6, and therefore have not altered it to use Perl6 modules. To that end this Transformer modifies C<use Foo;> declarations to use the Perl5 equivalent module, which is C<< use Foo:from<Perl5>;>>:

  use Foo; --> use Foo:from<Perl5>;

The C<use> declaration commonly imports functions or variables from external modules, such as C<use Carp qw(croak);>. This enforcer does not alter C<qw(croak)> to the Perl6 style of C<< <croak> >>, that is left to other enforcers.

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
