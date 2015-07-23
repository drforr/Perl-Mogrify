package Perl::Mogrify::Transformer::BasicTypes::Strings::Interpolation;

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::Util qw( min );
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
#
# Check whether a string has variables that interpolate.
#
sub _nearest_variable {
    my ($self, $string) = @_;

    my @var = grep { $_ != -1 } (
        index( $string, '@' ),
        index( $string, '\\@' ),
        index( $string, '$' ),
        index( $string, '\\$' ),
    );
    return -1 unless @var;

    return min(@var);
}

sub tokenize_variables {
    my ($self, $old_string) = @_;

    my @out;
    while ( $old_string ) {
        my $index = $self->_nearest_variable($old_string);

        # No can haz cheezburger.
        #
        if ( $index == -1 ) {
            push @out, $old_string;
            last;
        }

        # Can haz variable, we iz on start.
        #
        elsif ( $index == 0 ) {
            if ( $old_string =~ s{ ^ (\\\$ | \\\@) }{}x ) {
                my $v = $1;
                my $_next_variable = $self->_nearest_variable($old_string);

                # We've eaten the '\\$' or '\\@' at the start, look forward
                # to find the next variable.
                #
                # If there isn't one, reform what we had and bail
                # 
                # Otherwise, push everything up until the next variable.
                #
                if ( $_next_variable > -1 ) {
                    $v .= substr( $old_string, 0, $_next_variable, '' );
                    push @out, $v;
                }
                else {
                    push @out, $v . $old_string;
                }
            }
            else {
                my ( $var_name, $remainder, $prefix ) =
                     extract_variable( $old_string );
                push @out, $var_name;
                $old_string = $remainder;
                next;
            }
        }

        # Variable starts later in the string.
        #
        else {
            push @out, substr( $old_string, 0, $index, '' );
            # we accidentally the string.
            next;
        }
    }
    if ( $old_string ) {
        push @out, $old_string;
    }

    return @out;
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

    # Keep track of the \L..\E nesting depth.
    # We have to weave the \L..\E, \U..\E in at the same time as we're
    # interpolating.
    #
    my $depth = 0;
    if ( $old_string =~ / \{ /x ) {
        my @tokens = $self->tokenize_variables($old_string);
        my $collected;

        for my $token ( @tokens ) {

            # Tokens that start with $ or @ don't get their {} escaped.
            # There is one other thing that *might* happen to them, though.
            # It *could* be that $foo, $x[1]{'a'} &c is *preceded* by a \l or \u
            #
            # In this case, some fun happens.
            # We reach back into the collected string, and
            # remove the offending \l or \u, and save it for later.
            #
            # Then we check if we're already inside a \L..\E construct, and
            # if we are, then just wrap the variable in lcfirst(...) or uc
            # as appropriate.
            #
            # Thankfully, $x{\LA\E} and $x{\lA} get parsed oddly so they'll
            # probably never be used in real code. And I just jinxed myself
            # because someone will find a way to.
            #
            if ( $token =~ m{ ^ ( \$ | \@ ) }x ) {

                # If there's a \l or \u operator immediately before the 
                # variable, wrap it in Perl6 code to lcfirst/ucfirst as
                # appropriate.
                #
                if ( $collected and
                     $collected =~ s{ \\([lu]) $ }{}x ) {
                    if ( $depth == 0 ) {
                        $collected .= qq{{${1}cfirst($token)}};
                    }
                    else {
                        $collected .= qq{${1}cfirst($token)};
                    }
                }
                else {
                    $collected .= $token;
                }
            }

            # We don't have to worry about this being a Perl5 code block,
            # so just blindly escape it.
            #
            # However, it could contain \F..E blocks.
            # It's also important to remember that \l\U..\E is possible
            # as well so we'll look behind for those tokens while splitting.
            #
            else {
                $token =~ s{ (\{|\}) }{\\$1}gx;

                if ( $depth > 0 ) {
                    $collected .= qq{$start_delimiter$token$end_delimiter~};
                }
                else {
                    $collected .= $token;
                }
            }
        }
        $old_string = $collected;
    }

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
