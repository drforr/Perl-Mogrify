#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'BasicTypes::Strings::RenameShell', *DATA );

__DATA__
## name: transform
qx{};
qx{} if 1;
qx{} and 1;
1 if qx{};
1 and qx{};
my $x = qx{};
qx();
my $x = qx();
##-->
qqx{};
qqx{} if 1;
qqx{} and 1;
1 if qqx{};
1 and qqx{};
my $x = qqx{};
qqx();
my $x = qqx();
