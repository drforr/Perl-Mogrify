package Perl::Mogrify::Transformer::Pragmas::FormatPragmas;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };
use Perl::Mogrify::Utils::PPI qw{ is_version_number is_pragma };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Delete unnecessary pragmas};
Readonly::Scalar my $EXPL =>
    q{Pragmas such as 'strict', 'warnings', 'utf8' and 'version' are unnecessary or redundant};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

my %excluded_pragma = (
    v6 => 1,
    constant => 1, # 'use constant FOO => 1' --> 'constant FOO = 1' later
    base => 1, # 'use base "Foo::Mommy' --> 'class Foo is Foo::Mommy' later
    parent => 1, # 'use parent "Foo::Mommy' --> 'class Foo is Foo::Mommy' later
);

#
# 'use strict;' --> ''
# 'use warnings;' --> ''
# 'no strict;' --> ''
# 'no warnings;' --> ''
# 'use 5.6;' --> ''
# 'use v6;' --> 'use v6;'
# 'use constant;' --> 'use constant;'
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $package_name = $elem->child(2);
    return unless is_version_number($package_name) or
                  is_pragma($package_name);
    return if exists $excluded_pragma{$package_name->content};

    $elem->remove;

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Pragma::FormatPragma - Remove unnecessary pragmas


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Removes uneeded Perl5 pragmas. More specifically, it removes all core pragmas except C<v6>, C<constant>, C<base> and C<parent>. The C<v6> pragma remains untouched, C<constant> will be transformed later into <constant FOO = 1>, C<base> and C<parent> are added to the class declaration:

  use strict; --> ''
  no strict 'refs'; --> ''
  use warnings; --> ''
  use constant FOO => 1; --> use constant FOO => 1;
  use base qw(Foo); --> use base qw(Foo);

Transforms pragmas outside of comments, heredocs, strings and POD.

The 'constant', 'base' and 'parent' pragmas are left untouched for later transformers, so that they can do their Perl6 things.

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
