package Perl::Mogrify::Transformer::Packages::FormatPackageDeclarations;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_ppi_token_word };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'package' declaration into 'class'};
Readonly::Scalar my $EXPL => q{The Perl6 equivalent of packages are classes.};

#-----------------------------------------------------------------------------

my %map = (
    package => 1
);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           {
    return sub {
        is_ppi_token_word($_[1],%map)
    }
}

#-----------------------------------------------------------------------------

#
# 'package Foo;' --> 'unit class Foo;'
# 'package Foo { ... }' --> 'class Foo { ... }'
# 'package #\nFoo;' --> 'unit class #\nFoo;'
#
sub transform {
    my ($self, $elem, $doc) = @_;

    $elem->set_content('class');
    my $next = $elem;
    while ( $next = $next->snext_sibling ) {
        last if $next->isa('PPI::Structure::Block');
        next if $next->isa('PPI::Token::Word');
        next if $next->isa('PPI::Token::Comment');
        $elem->insert_before( PPI::Token::Word->new('unit') );
        $elem->insert_before( PPI::Token::Whitespace->new(' ') );
        last;
    }

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Packages::FormatPackageDeclarations - Format 'package Foo;' declarations


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

The Perl6 equivalent of a Perl5 package is 'class'. Older Perl5 source uses C<package Foo;> while some more modern source uses C<package Foo { .. }> to delineate package boundaries:

  package Foo; --> unit class Foo;
  package
  Foo;         --> unit class\nFoo;
  package Foo { ... } --> class Foo { ... }

Other transformers will be responsible for ensuring that perl5 classes inherit correctly.

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
