package Perl::Mogrify::Transformer::Regexes::SwapRegexModifiers;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_token_operator };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Regex modifiers now appear at the start of expresions};
Readonly::Scalar my $EXPL =>
    q{Regex modifiers now appear at the start of expresions};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Regexp' }

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
#use YAML;warn Dump $elem;

    my $old_content = $elem->content;
    my %modifiers = $elem->get_modifiers;
    if ( keys %modifiers ) {
        my $modifiers = join '', sort keys %modifiers;
#warn "[$modifiers]";
        unless ( $elem->{operator} ) {
            $elem->{operator} = 'm';
            $elem->set_content( 'm' . $elem->content );
        }

        my $new_content = $elem->content;
        my $delim = (split //,($elem->get_delimiters)[-1])[-1];
#warn "[$delim]";
warn "[$new_content]";
        $new_content =~ s{^(.)}{$1:$modifiers};
warn "[$new_content]";
        $new_content =~ s{$delim.+?$}{$delim}e;
warn "[$new_content]";
        $elem->set_content( $new_content );
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Operators::FormatBinaryOperators - Transform binary operators to Perl6 equivalents


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Several Perl5 operators such as '->' and '.' have changed names, hopefully without changing precedence. Most binary operators transform in straightforward fashion, '->' changes to '.' and '.' changes to '~', but some, like 'x' are more complex and depend upon their context:

  1 + 1     --> 1 + 1
  1 % 7     --> 1 % 7
  Foo->[0]  --> Foo.[0]
  Foo->new  --> Foo.new
  'a' x 7   --> 'a' x 7
  ('a') x 7 --> 'a' xx 7

Transforms operators outside of comments, heredocs, strings and POD.

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
