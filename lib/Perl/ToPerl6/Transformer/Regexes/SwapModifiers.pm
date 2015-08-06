package Perl::ToPerl6::Transformer::Regexes::SwapModifiers;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Regex modifiers now appear at the start of expresions};
Readonly::Scalar my $EXPL =>
    q{Regex modifiers now appear at the start of expresions};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Regexp')
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $num_modifiers = keys %{ $elem->get_modifiers };
    my $modifiers =
        substr( $elem->content, -$num_modifiers, $num_modifiers, '' );
    my $old_modifiers = $modifiers;

    # 'g' gets replaced with 'c', 'c' is removed? As is 'o'?
    #
    $modifiers =~ s{[sgo]}{}g; # XXX

    for ( @{ $elem->{sections} } ) {
        $_->{position} += length($modifiers) + 3;
    }

    my $new_content = $elem->content;

    if( $elem->{operator} and
        $elem->{operator} eq '/' ) {
        $new_content = 'm' . $new_content;
        $elem->{operator} = 'm';
    }
    $new_content = 'm' . $new_content if $new_content =~ m{ ^ / }x;
    if ( $modifiers ) {
        $new_content =~ s{^(m|s|y|tr)}{$1:$modifiers:P5};
    }
    else {
        $new_content =~ s{^(m|s|y|tr)}{$1:P5};
    }
    $elem->{operator} = $1;
    $new_content =~ s{$old_modifiers$}{};

    $elem->set_content($new_content);

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Regexex::SwapModifiers


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

In Perl6, modifiers have moved to the start of the regular expression declaration, and some are no longer needed:

  m/foo/ --> m/foo/
  m/foo/x --> m/foo/
  m/foo/gi --> m:gi/foo/

Transforms regular expressions outside of comments, heredocs, strings and POD.

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
