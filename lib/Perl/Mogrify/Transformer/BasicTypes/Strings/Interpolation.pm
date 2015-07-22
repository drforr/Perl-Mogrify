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

# Retokenize input, with special attention paid to:
#
# '\$foo'
# '\$foo[XXX]{"yyy"}[32]' and so on, as these are literals.
#
sub _tokenize_string {
    my $elem = shift;
    my @out;

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

        # Note that \E,\F,\L,\U,\Q,\l,\u escapes are passed straight through.
        #
        if ( $v =~ / ^ \\ /x ) {

            # Once a '\$' is seen in the string, anything whatsoever up until:
            #
            #   Another escaped character (any character)
            #   A '$' or '@'
            #   The end of the string
            #   Brackets can be unbalanced, whatever. Doesn't matter.
            #
            # should be considered part of the literal. Braces, brackets, '',
            # anything.
            #
            # Of course, this still has to be postprocessed into Perl6 but
            # this is the hard bit.
            #
            if ( $v eq '\\$' ) {
                my $ctr = $i+1;
                while ( $elem->[$ctr] =~ s{ ^ ([^\$\@\\]+) }{}x ) {
                    $v .= $1;
                    $ctr++;
                }
                $i = $ctr;
                push @out, $v;
            }
            elsif ( $v eq '\\0' ) {
                if ( $la and $la =~ m{ ^ ([0-7]+) }x ) {
                    $elem->[$i+1] =~ s{ ^ ([0-7]+) }{}x;
                    push @out, qq{\\o[$1]};
                }
                else {
                    push @out, qq{\\o[0]};
                }
            }

            # Control character
            #
            # '\c{' is an edge case, as the split() will render this into
            # '\c', '', '{'
            #
            elsif ( $v eq '\\c' ) {
                my $c = '';
                if ( $la ) {
                    $c = substr( $elem->[$i+1], 0, 1, '' );
                }
                elsif ( $la2 ) {
                    $c = substr( $elem->[$i+2], 0, 1, '' );
                }
                push @out, sprintf qq{\\c[0x%x]}, ord($c);
            }
        }

        # Here's the fun bit.
        # Really not *that* bad, but it's a miniparser, in essence.
        #
        # Eat the identifier if it's there, and just for sanity's sake,
        # just keep track of [ ] { }, and when they balance then shove
        # the contents onto the string we're accumulating.
        #
        # It could be anything like "$x{2+$a{q'hi]]}}' admittedly, but...
        #
        elsif ( $v eq '$' ) {
push @out, $v;
        }
        elsif ( $v eq '@' ) {
push @out, $v;
        }
        elsif ( $v eq '%' ) {
push @out, $v;
        }
        elsif ( $v eq '{' ) { push @out, $v; }
        elsif ( $v eq '[' ) { push @out, $v; }
        elsif ( $v eq ']' ) { push @out, $v; }
        elsif ( $v eq '}' ) { push @out, $v; }
        else {
            push @out, $v;
        }
    }

    @out;
}

# When reintegrating, this expects that:
#
#   '\0...'
#   '\c...'
#   '\o...'
#   '\x...'
#   '\N...'
#
# are all proper perl6 tokens. If they're *not*, then it expects that the {}[]
# are unaltered.
#
#   '$_foo_bar_',
#   '${_foo_bar_}',
#   '$foo[1]{'a'}{qw{a}}[$x+1]', in fact pretty much anything that balances
#   there is a single token.
#
sub _reintegrate_string {
    my ( $elem, $start_delimiter, $end_delimiter ) = @_;
    my $final = '';

    my $state = {
        case => [],
    };

warn ">>" . join( '', map { ">$_<" } @{ $elem } ) . "<<\n";

    # Need this style of for() loop as we're going to modify $i.
    #
    # I guess we could go the iterator route and do
    # $state->{peeK}->() && $state->{next}->(),
    # but that seems needlessly complex.
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
        # This now does double duty, actually, as \cG and \N{FOO BAR} are
        # now prefixed by \c.
        #
        elsif ( $v =~ / ^ \\c / ) {
            $final .= $v;
        }

        # End of case or quotation range
        #
        # If we're out of modifiers, then add the closing brace.
        # We also perform the same check after exiting the loop, so that
        # we don't accidentally leave an unbalanced string.
        #
        elsif ( $v eq '\\E' ) {
            if ( $state->{case} and @{ $state->{case} } == 1 ) {
                $final .= '}';
            }
            pop @{ $state->{case} };
        }

        # Foldcase operator
        #
        elsif ( $v eq '\\F' ) {
            unless ( $state->{case} and @{ $state->{case} } ) {
                $final .= '{';
            }
            push @{ $state->{case} }, 'F';
        }

        # lowercase character
        #
        # \l "steals" the first character from \F,\L,\U,\Q
        #
        elsif ( $v eq '\\l' ) {
            if ( $la ) {
                my $c = substr( $elem->[$i+1], 0, 1, '' );
                $final .= qq{{lcfirst($start_delimiter$c$end_delimiter)}};
            }
            elsif ( !$la and
                     $la2 and ( $la2 eq '\\L' or
                                $la2 eq '\\U' ) and $la3 ) {
                my $c = substr( $elem->[$i+3], 0, 1, '' );
                $final .= qq{{lcfirst($start_delimiter$c$end_delimiter)}};
            }
            elsif ( $la2 ) {
                my $c = substr( $elem->[$i+2], 0, 1, '' );
                $final .= $c;
                $i+=2;
            }
            else {
                # Do nothing.
            }
        }

        # lowercase range
        #
        # They may be terminated by a \E, if present.
        # They can also nest, so \Lfoo\Lbar\Ebaz\E will look a bit odd.
        #
        # Also, not to be outdone, if \l or \u is in front, those steal a
        # glyph from the string.
        #
        elsif ( $v eq '\\L' ) {
            unless ( $state->{case} and @{ $state->{case} } ) {
                $final .= '{';
            }
            push @{ $state->{case} }, 'L';
        }

        # Octal character
        #
        # '\0' (0 as in 1-1) is an octal escape without braces
        #
        elsif ( $v =~ / ^ \\0 /x ) {
            $final .= $v;
        }

        # Quotemeta range start
        #
        elsif ( $v eq '\\Q' ) {
            unless ( $state->{case} and @{ $state->{case} } ) {
                $final .= '{';
            }
            push @{ $state->{case} }, 'Q';
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

        # Opening brace
        #
        elsif ( $v eq '{' ) {
            if ( $state->{case} and @{ $state->{case} } > 0 ) { # XXX fix later
                $final .= '\\{';
            }
            else {
                $final .= '\\{';
            }
        }

        # Closing brace
        #
        elsif ( $v eq '}' ) {
            if ( $state->{case} and @{ $state->{case} } > 0 ) { # XXX fix later
                $final .= '\\}';
            }
            else {
                $final .= '\\}';
            }
        }

        # Opening bracket
        #
        elsif ( $v eq '[' ) {
            if ( $state->{case} and @{ $state->{case} } > 0 ) { # XXX fix later
                $final .= '\\[';
            }
            else {
                $final .= '\\[';
            }
        }

        # Closing bracket
        #
        elsif ( $v eq ']' ) {
            if ( $state->{case} and @{ $state->{case} } > 0 ) { # XXX fix later
                $final .= '\\]';
            }
            else {
                $final .= '\\]';
            }
        }

        # Everything else.
        #
        # If we're inside a casefold (that is, if the case stack is nonempty)
        # then casefold the current item.
        #
        # This needs to be done to almost every term actually.
        #
        else {
            if ( $state->{case} and @{ $state->{case} } ) {
                if ( $state->{case}[0] eq 'L' ) {
                    $final .= qq{lc($start_delimiter$v$end_delimiter)};
                }
                elsif ( $state->{case}[0] eq 'U' ) {
                    $final .= qq{uc($start_delimiter$v$end_delimiter)};
                }
                elsif ( $state->{case}[0] eq 'Q' ) {
                    $final .= qq{quotemeta($start_delimiter$v$end_delimiter)};
                }
            }
            else {
                $final .= $v;
            }
        }
    }

    if ( $state->{case} and @{ $state->{case} } ) {
        pop @{ $state->{case} };
        $final .= '}';
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
    # But they do sneak inside \L,\U,\F,\Q to alter the first character.
    #
    # \L\U modifiers probably would stack if they were legal, but they aren't.
    # In any case, remove extras.
    #
    $old_string =~ s{ (\\[lu]) (\\[lu])+ }{$1}gx;
    $old_string =~ s{ (\\[LU]) (\\[LU])+ }{$1}gx;

    # Transform all of the perl5 special characters into Perl6 forms:

    # \t is unaltered.
    # \n is unaltered.
    # \r is unaltered.
    # \f is unaltered.
    # \b is unaltered.
    # \a is unaltered.
    # \e is unaltered.

    # \x{263a} now looks like \x[263a].
    $old_string =~ s{ \\x \{ ([0-9a-fA-F]+) \) }{\x[$1]}mgx;

    # \x12 is unaltered.

    # \xX is now illegal, and in perl5 it generated nothing.
    $old_string =~ s{ \\x \{ ([^0-9a-fA-F]) \) }{$1}mgx;

    # \x at the end of the string is still illegal.
    $old_string =~ s{ \\x $ }{}mx;

    # \N{U+1234} is now \x[1234].
    # ( whitespace is significant. )
    $old_string =~ s{ \\N \{ U \+ ([^0-9a-fA-F]) \) }{\x[$1]}mgx;

    # \N{LATIN CAPITAL LETTER X} is now \c[LATIN CAPITAL LETTER X]
    $old_string =~ s{ \\N \{([^\})+\} }{\x[$1]}mgx;

    # \o{2637} now looks like \o[2637].
    $old_string =~ s{ \\o \{ ([0-7]+) \) }{\o[$1]}mgx;

    # \o12 is unaltered.

    # \oX is now illegal, and in perl5 it generated nothing.
    $old_string =~ s{ \\o \{ ([^0-9]) \) }{$1}mgx;

    # \o at the end of the string is still illegal.
    $old_string =~ s{ \\o $ }{}mx;

    # \0123 is now \o[123].
    $old_string =~ s{ \\0 \{ ([0-7]) \) }{\o[$1]}mgx;

    # \0X is now illegal, and in perl5 it generated nothing.
    $old_string =~ s{ \\0 \{ ([^0-7]) \) }{$1}mgx;

    # \o at the end of the string is still illegal.
    $old_string =~ s{ \\0 $ }{}mx;

    # \cX is now illegal, and in perl5 it generated nothing.
    $old_string =~ s{ \\c (.) }{'\c[0x' . (sprintf "%x", ord( $1 )) . ']'}mgex;

    # \c at the end of the string is still illegal.
    $old_string =~ s{ \\c $ }{}mx;

    # Even though they only alter one character, \l and \u require special
    # treatment.
    #
    # And oo, what if someone was sneaky and wrote "\l\x{1234}"...
    #
    # Which ordinarily wouldn't be a problem, *but* we might be inside
    # a \L..\E range, which is *also* Perl6 code.
    #
    # So, we do a primitive tokenization pass on the strings, looking just for
    # \l, \u, \L, \U, \F, \Q, \E
    #
    # (Yes, Virginia, quotemeta interpolates in strings.)
    #

    # Split the string on '\\.', '$', '{', '[', ']', '}'
    #
    # These are all the important Perl5 characters to interpolated values.
    # I hope.
    #
    # Unlike perl6, this is a two-pass algorithm.
    # It could be done in one pass, but that makes
    # $x{a}[1][$foo] needlessly complex.
    #
    my @elem =
        split /( \\. | \$ | \% | \@ | \{ | \[ | \] | \} )/x, $old_string;
    my @token = _tokenize_string(\@elem);
    $new_string = _reintegrate_string(\@token, $start_delimiter, $end_delimiter);

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
