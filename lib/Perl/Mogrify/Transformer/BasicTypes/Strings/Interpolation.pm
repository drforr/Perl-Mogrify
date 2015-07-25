package Perl::Mogrify::Transformer::BasicTypes::Strings::Interpolation;

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::Util qw( max );
use Text::Balanced qw( extract_variable );

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
sub tokenize_variables {
    my ($self, $string) = @_;

    my @tokens;
my $iter = 100;
    while ( $string ) {
unless ( --$iter  ) {
    die "Congratulations, you've broken string interpolation. Please report this message, along with the test file you wer using to the author.";
}
        my $residue;
        if ( $string =~ s{ ^ ( [^\$\@]+ ) }{}x ) {
            $residue = $1;

            while ( $residue and $residue =~ / \\ $ /x ) {
                $string =~ s{ (.) }{}x;
                $residue .= $1;
                if ( $string =~ s{ ^ ( [^\$\@]+ ) }{}x ) {
                    $residue .= $1;
                }
                else {
                    last;
                }
            }
            push @tokens, split /( \\[luEFLQU] )/x, $residue;
        }
        elsif ( $string =~ m{ ^ [\$\@] }x ) {
            my ( $var_name, $remainder, $prefix ) =
                 extract_variable( $string );
            push @tokens, $var_name;
            $string = $remainder;
        }
        else {
        }
    }

    return grep { $_ ne '' } @tokens;
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

    # \l or \u followed *directly* by any \l or \u modifier simply ignores
    # the remaining \l or \u modifiers.
    #
    $old_string =~ s{ (\\[lu]) (\\[lu])+ }{$1}gx;

    # \F, \L or \U followed *directly* by any \F, \L or \U modifier is a
    # syntax error in Perl5, and can be reduced to a single \F, \L or \U.
    #
    $old_string =~ s{ (\\[FLU]) (\\[FLU])+ }{$1}gx;

    # \Q followed by anything is still a legal sequence.

    # \t is unchanged in Perl6.
    # \n is unchanged in Perl6.
    # \r is unchanged in Perl6.
    # \f is unchanged in Perl6.
    # \b is unchanged in Perl6.
    # \a is unchanged in Perl6.
    # \e is unchanged in Perl6.

    # \v is deprecated
    #
    $old_string =~ s{ \\v }{v}mgx;

    # \x{263a} now looks like \x[263a].
    #
    $old_string =~ s{ \\x \{ ([0-9a-fA-F]+) \} }{\\x[$1]}mgx;

    # \x12 is unaltered.
    # \x1L is unaltered.
    #
    # '..\x' is illegal in Perl6.
    #
    $old_string =~ s{ \\x $ }{}mx;

    # \N{U+1234} is now \x[1234].
    # Variants with whitespace are illegal in Perl5, so don't worry about 'em
    #
    $old_string =~ s{ \\N \{ U \+ ([0-9a-fA-F]+) \} }{\\x[$1]}mgx;

    # \N{LATIN CAPITAL LETTER X} is now \c[LATIN CAPITAL LETTER X]
    #
    $old_string =~ s{ \\N \{ ([^\}]+) \} }{\\c[$1]}mgx;

    # \o{2637} now looks like \o[2637].
    #
    # \o12 is unaltered.
    #
    $old_string =~ s{ \\o \{ ([0-7]*) \) }{\\o[$1]}mgx;

    # \0123 is now \o[123].
    #
    $old_string =~ s{ \\0 \{ ([0-7]*) \) }{\\o[$1]}mgx;

    # \oL is now illegal, and in perl5 it generated nothing.
    #
    # "...\o" is a syntax error in both languages, so don't worry about it.
    #
    $old_string =~ s{ \\o \{ ([^\}]*) \} }{\\o[$1]}mgx;

    # \c. is unchanged. Or at least I'll treat it as such.

    # At this point, you'll notice that practically every '{' and '}'
    # character is out of our target string, with trivial exceptions like
    # 'c{', which is illegal anyway.
    #
    # This is important for two main reasons. The first is that anything inside
    # {} in Perl6 is considered valid Perl6 code, which is also why a trick
    # we use later works.
    #
    # So, unless {} are part of a variable that can be interpolated, we have
    # to escape it. And we can't do that if there are constructs like \x{123}
    # hanging around in the string, because those would get messed up.
    #

    my @tokens = $self->tokenize_variables($old_string);

    my $collected;
    my @manip;
    for ( my $i = 0; $i < @tokens; $i++ ) {
        my ( $v, $la1 ) = @tokens[$i,$i+1];

        if ( $v !~ / ^ [\$\@] /x ) {
            $tokens[$i] =~ s< { ><\\{>gx;
            $tokens[$i] =~ s< } ><\\}>gx;
        }
        if ( $v eq '\\F' or $v eq '\\L' ) {
            unless ( @manip ) {
                $collected .= qq<{>;
            }
            $collected .= qq<lc($start_delimiter>;
            push @manip, $v;
        }
        elsif ( $v eq '\\Q' ) {
            unless ( @manip ) {
                $collected .= qq<{>;
            }
            $collected .= qq<quotemeta($start_delimiter>;
            push @manip, $v;
        }
        elsif ( $v eq '\\U' ) {
            if ( @manip ) {
                $collected .= qq<$end_delimiter~>;
            }
            else {
                $collected .= qq<{>;
            }
            $collected .= qq<uc($start_delimiter>;
            push @manip, $v;
        }
        elsif ( $v eq '\\E' ) {
            pop @manip;
            $collected .= qq<$end_delimiter)>;
            if ( @manip ) {
                my $last = $manip[-1];
                if ( $last eq '\\F' or $last eq '\\L' ) {
                    $collected .= qq<~lc($start_delimiter>;
                }
                elsif ( $last eq '\\Q' ) {
                    $collected .= qq<~quotemeta($start_delimiter>;
                }
                elsif ( $last eq '\\U' ) {
                    $collected .= qq<~uc($start_delimiter>;
                }
            }
            else {
                $collected .= qq<}>;
            }
        }
        else {
            $collected .= $v;
        }
    }
    if ( @manip ) {
        $collected .= $end_delimiter;
        for ( @manip ) {
            $collected .= qq<)>;
        }
        $collected .= qq<}>;
    }
    $old_string = $collected;

    set_string($elem,$old_string);

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
