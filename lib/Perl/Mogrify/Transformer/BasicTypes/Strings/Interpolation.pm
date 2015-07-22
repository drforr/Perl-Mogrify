package Perl::Mogrify::Transformer::BasicTypes::Strings::Interpolation;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ set_string };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Rewrite interpolated strings};
Readonly::Scalar my $EXPL => q{Rewrite interpolated strings};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return 'PPI::Token::Quote::Interpolate',
           'PPI::Token::Quote::Double'
}

#-----------------------------------------------------------------------------

sub _is_quoted {
    my ($string) = @_;
    return 1 if $string =~ / ^ ['"] /x and $string =~ / ['"] $ /x;
    return 1 if $string =~ / ^ qq [ ] (.) .* \1 $ /x;
    return 1 if $string =~ / ^ qq (.) .* \1 $ /x;
    return 1 if $string =~ / ^ q [ ] (.) .* \1 $ /x;
    return 1 if $string =~ / ^ q (.) .* \1 $ /x;
    return;
}

sub _reintegrate_string {
    my ( $elem, $start_delimiter, $end_delimiter ) = @_;
    my $final = '';

    my %state = (
        brace => 0
    );

warn ">>" . join( '', map { ">$_<" } @{ $elem } ) . "<<\n";

    # Need this style of for() loop as we're going to modify $i.
    #
    for ( my $i = 0; $i < @{ $elem }; $i++ ) {
        my ( $v, $la, $la2, $la3, $la4 ) =
            @{ $elem }[ $i, $i+1, $i+2, $i+3, $i+4 ];

        # Remember: $v,   $la, $la2, $la3,  $la4
        #           '\x', '',  '{',  '...', '}'
        #       
        my $braced_term;
        $braced_term = $la3 if $la2 and $la2 eq '{' and
                               $la4 and $la4 eq '}';

        my $bracketed_term;
        $bracketed_term = $la3 if $la2 and $la2 eq '[' and
                                  $la4 and $la4 eq ']';

        # Identifier start
        #
        if ( $v eq '$' ) {
        }

        # Control character
        #
        # '\c{' is an edge case, as the split() will render this into
        # '\c', '', '{'
        #
        elsif ( $v eq '\\c' ) {
            if ( $la ) {
                my $c = substr( $elem->[$i+1], 0, 1, '' );
                my $_v = sprintf "%x", ord( $c );
                $final .= qq{\\c[0x$_v]};
            }
            elsif ( $la2 ) {
                my $c = substr( $elem->[$i+2], 0, 1, '' );
                my $_v = sprintf "%x", ord( $c );
                $final .= qq{\\c[0x$_v]};
                $i += 2;
            }
            else {
                $final .= $v;
            }
        }

        # End of case or quotation range
        #
        elsif ( $v eq '\\E' ) {
        }

        # Foldcase operator
        #
        elsif ( $v eq '\\F' ) {
        }

        # lowercase character
        #
        elsif ( $v eq '\\l' ) {
            if ( $la ) {
                my $c = substr( $elem->[$i+1], 0, 1, '' );
                $final .= qq{{lcfirst($start_delimiter$c$end_delimiter)}};
            }
            elsif ( $la2 ) {
                my $c = substr( $elem->[$i+2], 0, 1, '' );
                $final .= $c;
                $i+=2;
            }
        }

        # lowercase range (balanced)
        #
        elsif ( $v eq '\\L' ) {
        }

        # Unicode character
        #
        # \N{U+1234} --> \x[1234]
        # \N{LATIN CAPITAL LETTER X} --> \c[LATIN CAPITAL LETTER X]
        #
        elsif ( $v eq '\\N' ) {
            if ( $braced_term ) {
                if ( $braced_term =~ m{ U \s* \+ \s* ( [0-9a-fA-F]{4} ) }x ) {
                    $final .= qq{\\x[$1]};
                }
                else {
                    $final .= qq{\\c[$braced_term]};
                }
                $i+=3;
            }
            else {
                $final .= $v;
            }
        }

        # Octal character
        #
        # \o{17} --> \x[f]
        #
        elsif ( $v eq '\\o' ) {
            if ( defined $braced_term and
                 $braced_term =~ m{ ^ ([0-7]+) $ }x ) {
                $final .= sprintf qq{\\o[$braced_term]};
                $i+=3;
            }
            elsif ( defined $braced_term ) {
                $final .= $v . $la . $la2 . $la3 . $la4;
                $i+=3;
            }
            else {
                $final .= $v;
            }
        }

        # Octal character
        #
        # '\0' (0 as in 1-1) is an octal escape without braces
        #
        elsif ( $v eq '\\0' ) {
            if ( $la and $la =~ m{ ^ ([0-7]+) }x ) {
                $elem->[$i+1] =~ s{ ^ ([0-7]+) }{}x;
                $final .= qq{\\o[$1]};
            }
            else {
                $final .= qq{\\o[0]};
            }
        }

        # Quotemeta range start
        #
        elsif ( $v eq '\\Q' ) {
        }

        # Uppercase character
        #
        elsif ( $v eq '\\u' ) {
            if ( $la ) {
                my $c = substr( $elem->[$i+1], 0, 1, '' );
                $final .= qq{{ucfirst($start_delimiter$c$end_delimiter)}};
            }
            elsif ( $la2 ) {
                my $c = substr( $elem->[$i+2], 0, 1, '' );
                $final .= $c;
                $i+=2;
            }
        }

        # Uppercase character range
        #
        elsif ( $v eq '\\U' ) {
        }

        # Vertical tab - Just 'v' in Perl6
        #
        elsif ( $v eq '\\v' ) {
            $final .= 'v';
        }

        # The start of a hex character
        #
        # '\X' isn't special.
        #
        elsif ( $v eq '\\x' ) {
            if ( $la2 and $la2 eq '{' and !$la3 and $la4 and $la4 eq '}' ) {
                $final .= qq{\\x[0]};
                $i+=3;
            }
            elsif ( defined $braced_term and
                 $braced_term =~ m{ ^ ([0-9a-fA-F]+) $ }x ) {
                $final .= sprintf qq{\\x[$braced_term]};
                $i+=3;
            }
            elsif ( defined $braced_term ) {
                $final .= $v . $la . $la2 . $la3 . $la4;
                $i+=3;
            }
            elsif ( $la2 and $la2 eq '{' and !$la3 and $la4 and $la4 eq '}' ) {
                $final .= qq{\\x[0]};
            }
            elsif ( $la and $la =~ m{ ^ ([0-9a-fA-F]+) }x ) {
                $elem->[$i+1] =~ s{ ^ ([0-9a-fA-F]+) }{}x;
                $final .= qq{\\x$1};
            }
            elsif ( !$la and
                     defined $la2 ) {
                $final .= qq{x$la2};
                $i+=2;
            }
            else {
                $final .= 'x';
            }
        }

        # Opening brace
        #
        elsif ( $v eq '{' ) {
        }

        # Closing brace
        #
        elsif ( $v eq '}' ) {
        }

        # Opening bracket
        #
        elsif ( $v eq '[' ) {
        }

        # Closing bracket
        #
        elsif ( $v eq ']' ) {
        }

        # Everything else.
        #
        else {
            $final .= $v;
        }
    }
    $final;
}

sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_string = $elem->string;
    my $new_string;

    # Save the delimiters for later. Since they surrounded the original Perl5
    # string, we can be certain that if we use these for the Perl6 equivalent
    # they'll be valid.
    # Yes, even in the case of:
    #
    # "\lfoo" -> "{lcfirst("f")}oo".
    #
    # Perl6 is smart enough to know which segment of the braid it's on, and
    # interprets the {..} boundary as a new Perl6 block.
    #
    my ( $start_delimiter ) =
        $elem->content =~ m{ ^ ( qq[ ]. | qq. | q[ ]. | q. | . ) }x;
    my $end_delimiter = substr( $elem->content, -1, 1 );

    # Almost forgot, the \l,\u modifiers don't stack. No matter how many
    # \l\u\u\l you encounter in a row, it will only ever be the first
    # modifier that gets used.
    #
    # \L\U modifiers probably would stack if they were legal, but they aren't.
    #
    $old_string =~ s{ (\\[lu]) (\\[lu])+ }{$1}gx;

    # Split the string on '\\.', '$', '{', '[', ']', '}'
    #
    # These are all the important Perl5 characters to interpolated values.
    #
    my @elem = split /( \\. | \$ | \{ | \[ | \] | \} )/x, $old_string;
    $new_string = _reintegrate_string(\@elem, $start_delimiter, $end_delimiter);

#        # The opening braces we're interested in--------V
#        #   Begin a hash key interpolation           "$x{a}"
#        #   Begin a Unicode character name           "\N{SMILEY FACE}"
#        #   Begin a hex number                       "\x{12ab}"
#        #   Begin an noninterpolated scalar          "\${x}"
#        #   Begin an interpolated scalar              "${x}"
#        #   Begin an noninterpolated text block       "${\x}"
#        #     Which could be preceded by a variable "$x${\x}"
#        #   Begin an interpolating @{[..]} block      "@{[..]}" # Later :)
#        #
#        elsif ( $v eq '{' ) {
#            
#            if ( $new_content =~ m{ \$\w+ [-]> $}x and
#                 $elem[$i+1] and
#                 $elem[$i+2] and
#                 $elem[$i+2] eq '}' ) {
#                $new_content =~ s{ (\$\w+) [-]> $}{$1.}x;
#                if ( _is_quoted($elem[$i+1]) ) {
#                    $new_content .= qq{{$elem[$i+1]}};
#                }
#                else {
#                    $elem[$i+1] =~ s{'}{\\'}g;
#                    $new_content .= qq{{'$elem[$i+1]'}};
#                }
#                $new_content .= $elem[$i+2];
#                $i += 2;
#            }
#            if ( $new_content =~ m{ \$\w+ $}x and
#                 $elem[$i+1] and
#                 $elem[$i+2] and
#                 $elem[$i+2] eq '}' ) {
#                $new_content =~ s{ (\$\w+) $}{$1}x;
#                if ( _is_quoted($elem[$i+1]) ) {
#                    $new_content .= qq{{$elem[$i+1]}};
#                }
#                else {
#                    $elem[$i+1] =~ s{'}{\\'}g;
#                    $new_content .= qq{{'$elem[$i+1]'}};
#                }
#                $new_content .= $elem[$i+2];
#                $i += 2;
#            }
#            elsif ( $new_content =~ / \\ N $/x and
#                 $elem[$i+1] and
#                 $elem[$i+1] =~ / ^ [A-Z ]+ $ /x and
#                 $elem[$i+2] and
#                 $elem[$i+2] eq '}' ) {
#                $new_content =~ s< \\ N $><\\c>x;
#                $new_content .= '[' . $elem[$i+1] . ']';
#                $i += 2;
#            }
#            elsif ( $new_content =~ / \\ [xX] $/x and
#                    $elem[$i+1] and
#                    $elem[$i+1] =~ / ^ [0-9a-fA-F ]+ $ /x and
#                    $elem[$i+2] and
#                    $elem[$i+2] eq '}' ) {
#                $new_content .= '[' . $elem[$i+1] . ']';
#                $i += 2;
#            }
#            elsif ( $new_content =~ / \\ \$ $/x and
#                    $elem[$i+1] and
#                    $elem[$i+2] and
#                    $elem[$i+2] eq '}' ) {
#                $new_content .= '\\{' . $elem[$i+1] . '\\}';
#                $i += 2;
#            }
#            elsif ( $new_content =~ / \$ $/x and
#                    $elem[$i+1] and
#                    $elem[$i+2] and
#                    $elem[$i+2] eq '}' ) {
#                $new_content =~ s< \$ $><{\$>x;
#                $new_content .= $elem[$i+1] . '}';
#                $i += 2;
#            }
#            else {
#                $new_content .= '\\' . $v;
#            }
#        }
#        elsif ( $v eq '}' ) {
#            $new_content .= '\\' . $v;
#        }
#        else {
#            $new_content .= $v;
#        }
#    }

    set_string($elem,$new_string);

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Strings::Interpolation - Format C<${x}> correctly


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
