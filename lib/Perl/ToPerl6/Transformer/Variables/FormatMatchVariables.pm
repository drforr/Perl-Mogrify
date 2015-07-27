package Perl::ToPerl6::Transformer::Variables::FormatMatchVariables;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :characters :severities };

use base 'Perl::ToPerl6::Transformer';

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform $1..$n to $0..$n-1};
Readonly::Scalar my $EXPL => q{Transform $1..$n to $0..$n-1};

#-----------------------------------------------------------------------------

#    '$1'     => '$0', # And so on,  make sure they don't get modified twice
#    '$2'     => '$1',
#    '$3'     => '$2',
#    '$4'     => '$1',

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Token::Magic') and
        $_[1]->content =~ / ^ \$ \d+ $ /x
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;
    my $old_content = $elem->content;

    $old_content =~ m/ ^ \$ (\d+) $ /x;

    my $new_content = q{$} . ($1 - 1);

    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Variables::FormatSpecialVariables - Format special variables such as @ARGV


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 renames many special variables, this changes most of the common variable names, including replacing some of the more obscure variables with new Perl6 equivalent code:

  @ARGV --> @*ARGS
  @+    --> (map {.from},$/[*])

Other variables are no longer used in Perl6, but will not be removed as likely they have expressions attached to them. These cases will probably be dealt with by adding comments to the expression.

Transforms special variables outside of comments, heredocs, strings and POD.

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
