package Perl::ToPerl6::Transformer::RewriteSpecialLiterals;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform '__END__' etc.};
Readonly::Scalar my $EXPL => q{__END__ and __DATA__ are now POD markers};

#-----------------------------------------------------------------------------

my %map = (
    '__END__'     => '=finish',
    '__FILE__'    => '$?FILE',
    '__LINE__'    => '$?LINE',
    '__PACKAGE__' => '$?PACKAGE',
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        ( $_[1]->isa('PPI::Token::Separator') or
          $_[1]->isa('PPI::Token::End') or
          $_[1]->isa('PPI::Token::Word') ) and
        exists $map{$_[1]->content}
    }
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    if ( $elem->isa('PPI::Token::Word') ) {
        my $new_content = $elem->content;
        $elem->set_content($map{$new_content});
    }
    elsif ( $elem->isa('PPI::Token::Separator') ) {
        my $new_content = $elem->content;
        $elem->set_content($map{$new_content});
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::RewriteSpecialLiterals - Format __END__, __LINE__ &c

=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

__END__ is replaced with the POD marker '=finish', and you can read beyond this boundary with the filehandle C<$*FINISH>:

  __END__ --> =finish
  __LINE__ --> $?LINE
  __FILE__ --> $?FILE
  __PACKAGE__ --> $?PACKAGE

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
