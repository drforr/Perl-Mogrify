package Perl::Mogrify::Transformer::BasicTypes::Strings::InterpolatedCase;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Handle \l,\u,\L,\U,\E};
Readonly::Scalar my $EXPL => q{Handle \l,\u,\L,\U,\E};

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

# This is a very sharp edge case, and admittedly nost people won't cut
# themselves on it.
#
# Basically, "\lADY" lower-cases the first character of the string "ADY", so
# that you get 'aDY' on your output. This works with variables too, so:
# "\l$ady" lowercases te first character of whatever's in $ady.
#
# Perl6 no longer has these "operators", so we have to emulate them.
#
# It would be easy to simply do the work ourselves, and outupt "aDY" in the
# first case, and {lcfirst $ady} in the second. But Perl6 and Perl5
# case semantics may not necessarily match, so what we do instead in the
# cases are:
#
# "\lADY" --> "{lcfirst('A')}DY"
# "\l$ady" --> "{lcfirst($ady)}"
#
# Really lc() would suffice, but lcfirst() is more explicit.
#
# \L and \U are even more fun, in that they force case until they run out of
# string to modify, or \E.
#
# So, we get output like this:
#
# "\Lady $bug ${Lady}\E" --> "{lc('ady ' ~ $bug ~ ' ' ~ $Lady)}"
#
# The parser assumes that anything other than '$' after a \l &c is a single
# character that the programmer wanted to case-shift.
#
# Thankfully only \l$foo is legal, \l@foo and \l%foo were never implemented.
# That throws a syntax error, but the parser ignores that.
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->content;
    my $new_content;
    my ( $expression, $remainder );

    # The string has a \l, \u, \L or \U operator in it somewhere.
    # For the moment, *IGNORE* \${...} and @{[...]} "operators."
    #
    # Everything up to the first \\ is just static text, so that immediately
    # gets pushed onto the waste string.
    #
    while ( $old_content and
            $old_content =~ s{ ^ ([^\\]+) }{}x ) {
        $new_content .= $1;

        # The string now starts with some sort of \\ character.
        # First, check to see if it's a \l or \u operator.
        #
        if ( $old_content =~ s{ ^ \\([lu]) }{}x ) {
            my $case = $1;

            # Ignore further \l, \u, and even \E because there's no \[LU]
            # to start.
            #
            $old_content =~ s{ ^ (\\[luE])+ }{}x;

            # \l and \u on a scalar act as 'lcfirst'/'ucfirst'.
            #
            # So, capture the variable name (whether '$foo' or '${foo}'),
            # enclose it in a Perl6 block and apply 'lcfirst' or 'ucfirst'
            # as needed.
            #
            if ( $old_content =~ s{ ^ \$(\w+) }{}x or
                 $old_content =~ s{ ^ \$\{(\w+)\} }{}x ) {
                my $variable = $1;
                $new_content .= qq{{${case}cfirst(\$$variable)}};
            }

            # \l and \u on arrays and hashes are thankfully illegal, so:
            #
            # \l on *any* other character than '$' is treated as case-shifting
            # that character.
            #
            elsif ( $old_content =~ s{ ^ (.) }{}x ) {
                my $character = $1;
                $character = q{\\'} if $character eq "'";
                $new_content .= qq{{${case}cfirst('$character')}};
            }
        }

        #
        # \L, \U case-shift everything until the first \E, or EOS
        # 
        elsif ( $old_content =~ s{ ^ \\([LU]) (.+?)( \\E | $ ) }{}x ) {
            my $case = lc($1);
            my $shifted = $2;

            # Filter out any other \l, \u, \L, \U operators
            #
            $shifted =~ s{ ^ (\\[luLU])+ }{}xg;

            my $perlified;

            while ( $shifted =~ s{ ^ ([^\$]+) }{}x ) {
                $perlified .= qq{'$1'};
 
                if ( $shifted =~ s{ ^ \$(\w+) }{}x ) {
                    $perlified .= qq{ ~ \$$1};
                }
                elsif ( $shifted =~ s{ ^ \$\{(\w+)\} }{}x ) {
                    $perlified .= qq{ ~ \$$1};
                }
            }

            $new_content .= qq{{${case}c($perlified)}};
        }

        # Pass other escapes through.
        #
        elsif ( $old_content =~ s{ ^ \\(.) }{}x ) {
            $new_content .= qq{\\$1};
        }
    }

    $elem->set_content( $new_content );

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
