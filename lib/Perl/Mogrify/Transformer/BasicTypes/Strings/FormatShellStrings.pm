package Perl::Mogrify::Transformer::BasicTypes::Strings::FormatShellStrings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform qx{...} to qqx{...}};
Readonly::Scalar my $EXPL => 
    q{Perl6 supports qx{}, but the perl5ish version is qqx{}};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::QuoteLike::Command' }

#-----------------------------------------------------------------------------

#
# A PPI::Token::QuoteLike::Command object contains a single string which has
# the entire 'qx{...}' token. Therefore we can't add a Token::Whitespace
# between the 'qr' and '{..}' like we can with loops and conditionals.
#

#
# qx{...} --> qqx{...}
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $content = $elem->content;

    $content =~ s{^qx\(}{qx (};
    $content =~ s{^qx}{qqx};

    $elem->set_content( $content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Strings::FormatInterpolatedStrings - Format C<${x}> correctly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 has a C<qx()> operator, but the C<qqx()> operator is more akin to Perl5:

  qx{..} --> qx{..}
  qx(..) --> qx (..)

This enforcer only operates on qx() constructs.

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
