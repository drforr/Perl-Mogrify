package Perl::Mogrify::Transformer::BasicTypes::Strings::InterpolatedCase;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Handle \l,\u,\L..\E,\U..\E};
Readonly::Scalar my $EXPL => q{Handle \l,\u,\L..\E,\U..\E};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        ( $_[1]->isa('PPI::Token::Quote::Interpolate') or
          $_[1]->isa('PPI::Token::Quote::Double') ) and
        $_[1]->content =~ /\\[luLU]/
    }
}

#-----------------------------------------------------------------------------

# This is how migraines begin.
#
# Let's start with the easy modifiers, q{\l} and q{\u}. All they do is
# case-shift the next character or first character of the variable they're
# next to. like so:
#
# "l\lAdy" --> "lady"
# $x="Ady"; "l\l$x" --> "lady"
# %x=(Ady => 1); "l\l%x" --> illegal, but we'll pretend like it's lc('%').
# @x=("Ady"); "l\l@x" --> illegal, but we'll pretend like it's lc('@').
#
# The Perl6 equivalent of this looks like:
#
# "l{lcfirst('A')dy"
# $x="Ady"; "l{lcfirst($x)}dy"
# @x=("Ady"); "l{lcfirst('@')}dy"
#
# Stacking 'operators' is legal but pointless, as the first 'operator' is what
# is used:
#
# "l\l\u\u\uAdy" --> "lady"
#
# Fairly straightforward, you say. And you'd be right.
# But, I hear you asking, what about case-shifting an arbitrary substring?
#
# That's where the \L..\E and \U..\E operators come in.
# (There's also \Q..\E, but let's jump off that bridge when we come to it.)
#
# Here's how they look when applied singly:
#
# "l\LADY\E" --> "lady"
# $x="Ady"; "l-\lLa-\lla-l\L$x\E" --> "l-la-la-lady"
#
# The Perl6 equivalents look like this:
#
# "l{lcfirst('ADY')}" --> "lady"
# $x="Ady"; "l-{lcfirst('L')}a-{lcfirst('L')}a-l{lcfirst($x)}" -->
#           "l-la-la-lady"
#
# It gets better. They nest:
#
# "l\lAdy l\LADY\E l-\lL-\lL-LADY\E\E" --> "lady lady l-l-lady"
#
# Which translates to this:
#
# "l{lcfirst('A')}dy l{lc('ADY')} l-{lc('L-' ~ lc('L-LADY'))}"
#
# And how do they interact with \l and \u? They nullify them:
#
# "\L WHISKY \uTANGO FOXTROT\E" --> "whisky tango foxtrot"
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->string;
    my ( $new_content, $token );

    # Strings of \l\l\u\u modifiers are equivalent to the first modifier.
    # Remove these before splitting, it simplifies the algorithm.
    #
    # \L\L\U\U modifiers are syntax errors, but remove them anyway.
    #
    $old_content =~ s/(\\[lu])(?:\\[lu])+/$1/g;
    $old_content =~ s/(\\[LU])(?:\\[LU])+/$1/g;

    my ( $start_delim ) = $elem->content =~ m{ ^ ( " | qq[^ ] | qq[ ](.) ) }x;
    my ( $start_escape ) = substr( $start_delim, -1, 1 );
    my ( $end_delim ) = $elem->content =~ m{ ( . ) $ }x;
    my ( $end_escape ) = $end_delim;

    #
    # Because Perl6 is 'turtles all the way down" so to speak, anything *inside*
    # a Perl6 codeblock is a full Perl6 expression.
    #
    # So, while "foo{'x'+'y'}bar" is a legitimate expression,
    # so is "foo{"x"+"y"}bar", even *with* the "" inside braces.
    #

    # Performing a bit of evil in the split() expression here.
    # Specifically, splitting on either '\lX' where X is the next character,
    # or '\L' without the next character.
    #
    # This is because \lfoo only affects the next character, and we can
    # rewrite just this one character in the expression.
    #
    my $depth = 0;
    for my $v ( split /(\\[lu].|\\[LUE])/, $old_content ) {

        # Skip \E if we're outside a \[LU]..\E block.
        next if $v eq '\E' and $depth == 0;

        # Skip \[lu] if we're *inside* a \[LU]..\E block.
        #
        next if $v =~ /\\[lu]/ and $depth > 0;

        if ( $v =~ /^\\l(.)/ ) {
            $new_content .= qq{{lcfirst(${start_delim}$1${end_delim})}};
        }
        elsif ( $v =~ /\\u(.)/ ) {
            $new_content .= qq{{ucfirst(${start_delim}$1${end_delim})}};
        }
        elsif ( $v eq '\\L' ) {
            if ( $depth == 0 ) {
                $new_content .= '{' if $depth == 0;
            }
            else {
                $new_content .= '~' if $new_content !~ /\($/;
            }
            $new_content .= 'lc(';
            $depth++;
        }
        elsif ( $v eq '\\U' ) {
            if ( $depth == 0 ) {
                $new_content .= '{' if $depth == 0;
            }
            else {
                $new_content .= '~' if $new_content !~ /\($/;
            }
            $new_content .= 'uc(';
            $depth++;
        }
        elsif ( $v eq '\\E' ) {
            $new_content .= ')';
            $depth--;
            $new_content .= '}' if $depth == 0;
        }
        elsif ( $v =~ /./ and $depth == 0 ) {
            $new_content .= $v;
        }
        elsif ( $v =~ /./ ) {
            $v =~ s{$start_escape}{\\$start_escape}g;
            $v =~ s{$end_escape}{\\$end_escape}g;
            $new_content .= '~' if $depth > 0 and $new_content =~ /\)$/;
            $new_content .= qq{${start_delim}$v${end_delim}};
        }
    }

    $new_content .= ')}' while $depth-- > 0;

    $elem->set_content(  $start_delim . $new_content . $end_delim );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::BasicTypes::Strings::InterpolateCase - Format "\Lfoo\E" and friends


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

This one takes a bit of explanation. In Perl5 there are some fairly obscure "modifiers" you can use to change case in strings while they're inline. For instance, C<print "In \Uheidelberg"> will print C<"In Heidelberg">, shifting the case of 'H'.

In Perl6, C<{}> delimits a new block wherever it occurs, even inside strings. As a consequence, C<"foo{$x+1}"> evaluates correctly, B<as does> C<"foo{print "foo"}">, even though the quoting would ordinarily seem to mean the statement parses as C<"foo{print ">, C<foo>, C<"}">.

So, we take advantage of that in the translation, like so:

  "foo" --> "foo" # No change.
  "\lfoo" --> "{lcfirst("f")}oo" # Yes, Virginia, it really *does* compile.
  "\LLOWER\Uupper\Enormal\E" -->  "{lc("LOWER"~uc("upper")~"normal")}"

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
