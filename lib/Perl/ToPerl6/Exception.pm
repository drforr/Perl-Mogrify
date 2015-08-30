package Perl::ToPerl6::Exception;

use 5.006001;
use strict;
use warnings;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::ToPerl6::Exception' => {
        isa         => 'Exception::Class::Base',
        description => 'A problem discovered by Perl::ToPerl6.',
    },
);

use Exporter 'import';

#-----------------------------------------------------------------------------

sub short_class_name {
    my ( $self ) = @_;

    return substr ref $self, (length 'Perl::ToPerl6') + 2;
}

#-----------------------------------------------------------------------------


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::Exception - A problem identified by L<Perl::ToPerl6|Perl::ToPerl6>.

=head1 DESCRIPTION

A base class for all problems discovered by
L<Perl::ToPerl6|Perl::ToPerl6>.  This exists to enable differentiating
exceptions from L<Perl::ToPerl6|Perl::ToPerl6> code from those
originating in other modules.

This is an abstract class.  It should never be instantiated.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<short_class_name()>

Retrieve the name of the class of this object with C<'Perl::ToPerl6::'>
stripped off.


=back


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
