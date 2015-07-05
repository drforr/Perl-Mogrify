package Perl::Mogrify::Transformer::BasicTypes::Strings::FormatInterpolatedStrings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{XXX SPLIT ME "${x}" is now "{$x}"};
Readonly::Scalar my $EXPL => q{XXX SPLIT ME Braces in Perl6 now delimit code blocks, so {x} is interpreted as {x()}};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    # "$x" --> "$x"
    # "${x}" --> "{$x}"
    # "\${x}" --> "\$\{x\}"

    my $interpolated = $doc->find('PPI::Token::Quote::Interpolate');
    my $double = $doc->find('PPI::Token::Quote::Double');

    my $string = [ ];
    push @{ $string }, @{ $interpolated }
        if $interpolated and ref $interpolated;
    push @{ $string }, @{ $double }
        if $double and ref $double;

    if ( $string and ref $string ) {
        for my $token ( @{ $string } ) {
            my $old_content = $token->content;
 
            $old_content =~ s{ (?: ^ | [^\\] ) \$\{(\w+)\} }{ '{$'.$1.'}' }gex;
 
            $token->set_content( $old_content );
        }
    }

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

In Perl6, contents inside {} are now executable code. That means that inside interpolated strings, C<"${x}"> will be parsed as C<"${x()}"> and throw an exception if C<x()> is not defined. As such, this transforms C<"${x}"> into C<"{$x}">:

  "The $x bit"      --> "The $x bit"
  "The ${x}rd bit"  --> "The {$x}rd bit"
  "The \${x}rd bit" --> "The \$\{x\}rd bit"

Transforms only interpolated strings outside of comments, heredocs and POD.

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
