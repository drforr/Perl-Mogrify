package Perl::Mogrify::Transformer::Packages::FormatPackageUsages;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_module_name is_pragma };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform 'use Foo;' to 'use Foo:from<Perl5>;'};
Readonly::Scalar my $EXPL =>
    q{Legacy Perl5 classes can be supported using Inline::Perl5 and the :from<Perl5> adverb};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

my %excluded_pragma = (
    constant => 1
);

#
# 'use Foo;' --> 'use Foo:from<Perl5>;'
# 'use Foo qw(a);' --> 'use Foo:from<Perl5> <a>;'
#
# Although this module only adjusts the 'Foo' bit.
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $package_name = $elem->child(2);
    return if is_pragma($package_name);
    return unless is_module_name($package_name);
    return if exists $excluded_pragma{$package_name->content};

    my $old_content = $package_name;
    $old_content .= ':from<Perl5>';
    $package_name->set_content($old_content);

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Packages::FormatPackageUsages - Format 'use Foo;' to 'use Foo:from<Perl5>;'


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Since this tool's main purpose is helping to migrate legacy code, it assumes that you've installed L<Inline::Perl5> in order to be able to load Perl5 classes.

Perl6 can use Perl5 classes through the use of the C<< :from<Perl5> >> adverb. Since this tool is meant to port existing Perl5 code, the transformer assumes that all C<use> statements it sees are for legacy code. Future transformers may migrate L<Test::More> code to Perl6 L<Test> modules:

  use Foo; --> use Foo:from<Perl5>;
  use Foo qw(a b); --> use Foo:from<Perl5> qw(a b);

Transforms 'use' statements outside of comments, heredocs, strings and POD.

Does B<not> transform C<qw()> statements into their more modern Perl5 C<< <> >> equivalent, that is left to later transformers.

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
