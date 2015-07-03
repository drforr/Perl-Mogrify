package Perl::Mogrify::Enforcer::Pragmas::FormatPragmas;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_version_number is_pragma };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Remove unnecessary pragmas, such as strict, warnings and old versions};
Readonly::Scalar my $EXPL =>
    q{Remove unnecessary pragmas, such as strict, warnings and old versions};

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
        # 'use strict;' --> ''
        # 'use warnings;' --> ''
        # 'no strict;' --> ''
        # 'no warnings;' --> ''
        # 'use 5.6;' --> ''
        # 'use v6;' --> 'use v6;'
        # 'use constant;' --> 'use constant;'
        #
        for my $pragma ( @{ $tokens } ) {
            my $package_name = $pragma->child(2);
            next unless is_version_number($package_name) or
                        is_pragma($package_name);
            next if $package_name->content eq 'v6';
            next if $package_name->content eq 'constant';

            $modified = 1;
            $pragma->remove;
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

Perl::Mogrify::Enforcer::Pragma::FormatPragma - Remove unnecessary pragmas


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 no longer needs or uses 'strict' or 'warnings' pragmas. This enforcer removes all references to the 'strict' and 'warnings' pragmas, whether they be C<use strict;>, C<no strict 'refs';> or just C<use warnings;>:

  use strict; -->
  no strict 'refs'; -->
  use warnings; --

Note that 'use constant' is not a pragma for the purposes of this Enforcer. This is because later on C<<use constant FOO => 1>> declarations will be replaced wit C<constant FOO = 1> declarations.

=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.

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
