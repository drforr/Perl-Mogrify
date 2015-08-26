#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'BasicTypes::Strings::RenameRegex', *DATA );

__DATA__
## name: transform
qr{};
qr{} if 1;
qr{} and 1;
1 if qr{};
1 and qr{};
my $x = qr{};
qr();
my $x = qr();
##-->
rx{};
rx{} if 1;
rx{} and 1;
1 if rx{};
1 and rx{};
my $x = rx{};
rx();
my $x = rx();
