package Perl::Mogrify::Transformer::BasicTypes::Strings::InterpolatedBraces;

use 5.006001;
use strict;
use warnings;
use Readonly;
use Text::Balanced qw{ extract_bracketed };

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"${x}" is now "{$x}"};
Readonly::Scalar my $EXPL => q{Braces in Perl6 now delimit code blocks, so {x} is interpreted as {x()}};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to {
    return 'PPI::Token::Quote::Interpolate',
           'PPI::Token::Quote::Double';
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
print "[".$doc->content."]\n";

    my $old_content = $elem->content;
    my $new_content;
    my ( $expression, $remainder );

    if ( $old_content =~ m/\{/ ) {
        while ( $old_content and
                $old_content =~ s{ ^ ([^\{]+) }{}x ) {
            $new_content .= $1;
            ( $expression, $remainder ) = extract_bracketed($old_content,'{}');
            if ( $expression ) {
                my $unbraced = substr( $expression, 1, -1 );
                if ( $new_content =~ s{( [\\]? [\$@] | \\N )$}{}x ) {
                    $expression = $1 . $expression;
                }
 
                if ( $expression =~ m{ ^ \\N }x ) {
                    $expression = qq{\\c[$unbraced]};
                }
                elsif ( $expression =~ m{ ^ \\ \$ }x ) {
                    $expression = qq{\\\$\\{$unbraced\\}};
                }
                elsif ( $expression =~ m{ ^ \$ }x ) {
                    $expression = qq{{\$$unbraced}};
                }
 
                $new_content .= $expression;
                $old_content = $remainder;
            }
        }
    }
    else {
        $new_content = $old_content;
    }

    $elem->set_content( $new_content );

print "[".$doc->content."]\n";
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
