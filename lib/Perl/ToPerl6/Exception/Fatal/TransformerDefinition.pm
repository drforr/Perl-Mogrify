package Perl::ToPerl6::Exception::Fatal::TransformerDefinition;

use 5.006001;
use strict;
use warnings;

use Readonly;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::ToPerl6::Exception::Fatal::TransformerDefinition' => {
        isa         => 'Perl::ToPerl6::Exception::Fatal',
        description => 'A bug in a transformer was found.',
        alias       => 'throw_transformer_definition',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_transformer_definition >;

#-----------------------------------------------------------------------------


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::Exception::Fatal::TransformerDefinition - A bug in a transformer.

=head1 DESCRIPTION

A bug in a transformer was found, e.g. it didn't implement a method that it should
have.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

Only inherited ones.


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
