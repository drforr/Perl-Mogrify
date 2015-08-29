package Perl::ToPerl6::Transformer::Pragmas::RewritePragmas;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::ToPerl6::Utils qw{ :severities };
use Perl::ToPerl6::Utils::PPI qw{ is_version_number is_pragma };

use base 'Perl::ToPerl6::Transformer';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Delete unnecessary pragmas};
Readonly::Scalar my $EXPL =>
    q{Pragmas such as 'strict', 'warnings', 'utf8' and 'version' are unnecessary or redundant};

#-----------------------------------------------------------------------------

my %map = (
    v6 => 1,
    constant => 1, # 'use constant FOO => 1' --> 'constant FOO = 1' later
    base => 1, # 'use base "Foo::Mommy' --> 'class Foo is Foo::Mommy' later
    parent => 1, # 'use parent "Foo::Mommy' --> 'class Foo is Foo::Mommy' later
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_necessity    { return $NECESSITY_HIGHEST }
sub default_themes       { return qw( core )         }
sub applies_to           {
    return sub {
        $_[1]->isa('PPI::Statement::Include') and
        ( is_version_number($_[1]->child(2))  or
          is_pragma($_[1]->child(2)) ) and
        not exists $map{$_[1]->child(2)->content}
    }
}

#-----------------------------------------------------------------------------

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

    $elem->remove;

    return $self->transformation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::ToPerl6::Transformer::Pragma::RewritePragmas - Remove unnecessary pragmas


=head1 AFFILIATION

This Transformer is part of the core L<Perl::ToPerl6|Perl::ToPerl6>
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
