package Perl::ToPerl6::Exception::Configuration::Option;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

use Perl::ToPerl6::Exception::Fatal::Internal;

use Exception::Class (   # this must come after "use P::C::Exception::*"
    'Perl::ToPerl6::Exception::Configuration::Option' => {
        isa         => 'Perl::ToPerl6::Exception::Configuration',
        description => 'A problem with an option in the Perl::ToPerl6 configuration, whether from a file or a command line or some other source.',
        fields      => [ qw{ option_name option_value message_suffix } ],
    },
);

#-----------------------------------------------------------------------------

sub message {
    my $self = shift;

    return $self->full_message();
}

#-----------------------------------------------------------------------------

sub error {
    my $self = shift;

    return $self->full_message();
}

#-----------------------------------------------------------------------------

sub full_message {
    Perl::ToPerl6::Exception::Fatal::Internal->throw(
        'Subclass failed to override abstract method.'
    );
}
## use mogrify


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::Exception::Configuration::Option - A problem with an option in the L<Perl::ToPerl6|Perl::ToPerl6> configuration.

=head1 DESCRIPTION

A representation of a problem found with an option in the
configuration of L<Perl::ToPerl6|Perl::ToPerl6>, whether from a
F<.perlmogrifyrc>, another profile file, or command line.

This is an abstract class.  It should never be instantiated.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<option_name()>

The name of the option that was found to be in error.


=item C<option_value()>

The value of the option that was found to be in error.


=item C<message_suffix()>

Any text that should be applied to end of the standard message for
this kind of exception.


=item C<message()>

=item C<error()>

Overridden to call C<full_message()>.  I.e. any message string in the
superclass is ignored.


=item C<full_message()>

Overridden to turn it into an abstract method to force subclasses to
implement it.


=back


=head1 SEE ALSO

L<Perl::ToPerl6::Exception::Configuration::Option::Global|Perl::ToPerl6::Exception::Configuration::Option::Global>
L<Perl::ToPerl6::Exception::Configuration::Option::Transformer|Perl::ToPerl6::Exception::Configuration::Option::Transformer>


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
