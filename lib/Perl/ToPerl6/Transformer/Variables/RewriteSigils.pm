package Perl::ToPerl6::Transformer::Variables::RewriteSigils;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform $x[0] to @x[0]};
Readonly::Scalar my $EXPL =>
    q{Perl6 uses the data type as the sigil now, not the context desired};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to {
    return 'PPI::Token::Symbol',
           'PPI::Token::ArrayIndex'
}

#-----------------------------------------------------------------------------

#
# %foo    --> %foo
# $foo{a} --> %foo{a} # Note it does not pointify braces.
# @foo    --> @foo
# $foo[1] --> @foo[1]
#
sub transform {
    my ($self, $elem, $doc) = @_;
    if ( $elem->isa('PPI::Token::ArrayIndex') ) {
        my $content = $elem->content;

        $content =~ s{\$#}{};

#
# There's a bug that causes $elem->parent to go away here.
# Not sure if it's PPI or not...
#
unless ( $elem->parent ) {
    warn "XXX PPI bug triggered\n";
    return;
}

        $elem->insert_before(
            PPI::Token::Symbol->new('@' . $content)
        );
        $elem->insert_before(
            PPI::Token::Symbol->new('.')
        );
        $elem->insert_before(
            PPI::Token::Word->new('end')
        );
        $elem->delete;
    }
    else {
        return if $elem->raw_type eq '@';
        return if $elem->raw_type eq '%';

        if ( $elem->next_sibling ) {
            my $subscript = $elem->snext_sibling;
            return unless $subscript->isa('PPI::Structure::Subscript');
            my $new_content = $elem->content;

            if ( $subscript->start eq '[' ) {
                substr($new_content, 0, 1) = '@';
            }
            elsif ( $subscript->start eq '{' ) {
                substr($new_content, 0, 1) = '%';
            }
            $elem->set_content( $new_content );
        }
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Variables::RewriteSigils - Give variables their proper sigils.


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
distribution.


=head1 DESCRIPTION

Perl6 uses the sigil type as the data type now, and this is probably the most common operation people will want to do to their file. This transformer doesn't alter hash keys or array indices, those are left to transformers down the line:

  @foo = () --> @foo = ()
  $foo[1] --> @foo[1]
  %foo = () --> %foo = ()
  $foo{a} --> %foo{a} # Not %foo<a> or %foo{'a'} yet.

Transforms variables outside of comments, heredocs, strings and POD.

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
