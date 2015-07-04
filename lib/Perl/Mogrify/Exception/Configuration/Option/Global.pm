package Perl::Mogrify::Exception::Configuration::Option::Global;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Mogrify::Exception::Configuration::Option::Global' => {
        isa         => 'Perl::Mogrify::Exception::Configuration::Option',
        description => 'A problem with global Perl::Mogrify configuration.',
    },
);

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Mogrify::Exception::Configuration::Option::Global - A problem with L<Perl::Mogrify|Perl::Mogrify> global configuration.

=head1 DESCRIPTION

A representation of a problem found with the global configuration of
L<Perl::Mogrify|Perl::Mogrify>, whether from a F<.perlmogrifyrc>, another
profile file, or command line.

This is an abstract class.  It should never be instantiated.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
