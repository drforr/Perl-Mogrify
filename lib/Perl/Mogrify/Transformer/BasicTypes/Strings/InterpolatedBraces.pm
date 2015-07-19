package Perl::Mogrify::Transformer::BasicTypes::Strings::InterpolatedBraces;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ set_string };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"${x}" is now "{$x}"};
Readonly::Scalar my $EXPL => q{Braces in Perl6 now delimit code blocks, so {x} is interpreted as {x()}};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        ( $_[1]->isa('PPI::Token::Quote::Interpolate') or
          $_[1]->isa('PPI::Token::Quote::Double') ) and
        $_[1]->string =~ /[\{\}]/
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->string;
    my $new_content;

    my $depth = 0;
    my @elem = split /(\\?[\{\}])/, $old_content;
    for ( my $i = 0; $i < @elem; $i++ ) {
        my $v = $elem[$i];

        # Pass escaped braces through
        #
        if ( $v eq '\\{' or $v eq '\\}' ) {
            $new_content .= $v;
        }

        # The opening braces we're interested in-------V
        #   Begin a Unicode character name           "\N{SMILEY FACE}"
        #   Begin a hex number                       "\x{12ab}"
        #   Begin an noninterpolated scalar          "\${x}"
        #   Begin an interpolated scalar              "${x}"
        #   Begin an noninterpolated text block       "${\x}"
        #     Which could be preceded by a variable "$x${\x}"
        #   Begin an interpolating @{[..]} block      "@{[..]}" # Later :)
        #
        elsif ( $v eq '{' ) {

            # For '\N{..}', mangle the 
            if ( $new_content =~ / \\ N $/x and
                 $elem[$i+1] and
                 $elem[$i+1] =~ / ^ [A-Z ]+ $ /x and
                 $elem[$i+2] and
                 $elem[$i+2] eq '}' ) {
                $new_content =~ s< \\ N $><\\c>x;
                $new_content .= '[' . $elem[$i+1] . ']';
                $i += 2;
            }
            elsif ( $new_content =~ / \\ [xX] $/x and
                    $elem[$i+1] and
                    $elem[$i+1] =~ / ^ [0-9a-fA-F ]+ $ /x and
                    $elem[$i+2] and
                    $elem[$i+2] eq '}' ) {
                $new_content .= '[' . $elem[$i+1] . ']';
                $i += 2;
            }
            elsif ( $new_content =~ / \\ \$ $/x and
                    $elem[$i+1] and
                    $elem[$i+2] and
                    $elem[$i+2] eq '}' ) {
                $new_content .= '\\{' . $elem[$i+1] . '\\}';
                $i += 2;
            }
#            elsif ( $new_content =~ / \$ $/x and
#                    $elem[$i+1] and
#                    $elem[$i+1] =~ / ^ \\/x and
#                    $elem[$i+2] eq '}' ) {
#                $new_content =~ s< \$ $><{\$>x;
#                $new_content .= $elem[$i+1] . '}';
#                $i += 2;
#            }
            elsif ( $new_content =~ / \$ $/x and
                    $elem[$i+1] and
                    $elem[$i+2] and
                    $elem[$i+2] eq '}' ) {
                $new_content =~ s< \$ $><{\$>x;
                $new_content .= $elem[$i+1] . '}';
                $i += 2;
            }
            else {
                $new_content .= '\\' . $v;
                $depth--;
            }
        }
        elsif ( $v eq '}' ) {
            $new_content .= '\\' . $v;
            $depth--;
        }
        else {
            $new_content .= $v;
        }
    }

    set_string($elem,$new_content);

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Strings::InterpolatedBraces - Format C<${x}> correctly


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

In Perl6, contents inside {} are now executable code. That means that inside interpolated strings, C<"${x}"> will be parsed as C<"${x()}"> and throw an exception if C<x()> is not defined. As such, this transforms C<"${x}"> into C<"{$x}">:

  "The $x bit"      --> "The $x bit"
  "The $x-30 bit"   --> "The $x\-30 bit"
  "\N{FOO}"         --> "\c{FOO}"
  "The \l$x bit"    --> "The {lc $x} bit"
  "The \v bit"      --> "The  bit"
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
