package Perl::ToPerl6::Exception::Configuration::Option::Transformer;

use 5.006001;
use strict;
use warnings;

use Perl::ToPerl6::Utils qw{ &transformer_short_name };

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::ToPerl6::Exception::Configuration::Option::Transformer' => {
        isa         => 'Perl::ToPerl6::Exception::Configuration::Option',
        description => 'A problem with the configuration of a transformer.',
        fields      => [ qw{ transformer } ],
    },
);

#-----------------------------------------------------------------------------

sub new {
    my ($class, %options) = @_;

    my $transformer = $options{transformer};
    if ($transformer) {
        $options{transformer} = transformer_short_name($transformer);
    }

    return $class->SUPER::new(%options);
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::Exception::Configuration::Option::Transformer - A problem with configuration of a transformer.

=head1 DESCRIPTION

A representation of a problem found with the configuration of a
L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer>, whether from a
F<.perlmogrifyrc>, another profile file, or command line.

This is an abstract class.  It should never be instantiated.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<transformer()>

The short name of the transformer that had configuration problems.


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
