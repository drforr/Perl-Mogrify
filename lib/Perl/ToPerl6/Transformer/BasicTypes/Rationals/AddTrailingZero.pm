package Perl::ToPerl6::Transformer::BasicTypes::Rationals::AddTrailingZero;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Add trailing 0 after decimal point};
Readonly::Scalar my $EXPL => q{'1.' is no longer a valid floating-point number fomat};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           { return 'PPI::Token::Number::Float' }

#-----------------------------------------------------------------------------

sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->content;
 
    my ( $lhs, $rhs ) = split( /\./, $old_content );
    return if $rhs and $rhs ne '';
 
    my $new_content = $lhs . '.0';
    
    $elem->set_content( $new_content );

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::BasicTypes::Rationals::AddTrailingZero - Add trailing zero where needed


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 floating-point values have the format '1.0' where a trailing digit is required:

  1.0 --> 1.0
  1.  --> 1.0
  .1  --> .1

Transforms floating-point numbers outside of comments, heredocs, strings and POD.

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
