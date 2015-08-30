package Perl::ToPerl6::Transformer::CompoundStatements::RewriteLoops;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{
    insert_trailing_whitespace
};

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform C-style 'for()' to 'loop ()'};
Readonly::Scalar my $EXPL => q{C-style for() is now 'loop'};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }

#-----------------------------------------------------------------------------

my %conditional = (
    for     => 'loop',
    foreach => 'loop',
);

sub _structure_has_semicolon {
    my ($elem) = @_;
    $elem = $elem->child(1);
    while ( $elem ) {
        return 1 if $elem->isa('PPI::Token::Structure');
        $elem = $elem->next_sibling;
    }
    return;
}

sub _is_c_style {
    my ($elem) = @_;
    $elem = $elem->child(1);
    while ( $elem->next_sibling ) {
        return 1 if $elem->isa('PPI::Statement::Null');
        return 1 if $elem->isa('PPI::Statement') and
                    _structure_has_semicolon($elem);
        $elem = $elem->next_sibling;
    }
    return;
}

#
# There's a tradeoff at work here.
#
# While the PPI::Structure::For object is the correct type to look for
# (specifically, it accurately matches the 'for ( ) ...' construct)
# it matches the '(...)' element, not the structure containing the emtire 'for'
# block.
#
# So we search for the PPI::Structure::For object, and when the time comes
# to transform the object, we just move our "pointer" up to the parent,
# which contains the entire 'for () {}' construct.
#

sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Structure::For') and
        _is_c_style($_[1])
    }
}

#-----------------------------------------------------------------------------

# Note to reader: (after moving $elem up one layer) the structure looks like
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0    1  # count by child()
#    \0    1  # count by schild()
#     +----+
#     |    |
#     for  ( )
#
# After changing child(0):
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0    1  # count by child()
#    \0    1  # count by schild()
#     +----+
#     |    |
#     loop ( )
#
# After inserting ' ' after schild(0):
#
# $elem (PPI::Statement::Compound)
#  \
#   \ 0    1    2  # count by child()
#    \0         1  # count by schild()
#     +----+----+
#     |    |    |
#     loop ' ' ( )

sub transform {
    my ($self, $elem, $doc) = @_;
    $elem = $elem->parent;

    $elem->schild(0)->set_content('loop');

    insert_trailing_whitespace($elem->schild(0));

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::CompoundStatements::RewriteLoops - Format for(;;) loops


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 changes C-style C<for> loops to use the name C<loop>:

  for(@a) --> for (@a)
  for($i=0;$i<1;$i++) --> loop ($i=0;$i<1;$i++)

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
