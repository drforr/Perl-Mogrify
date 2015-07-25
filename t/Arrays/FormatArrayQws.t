#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Arrays::FormatArrayQws', *DATA );

__DATA__
## name: transform
qw{a b c};
qw{a b c} if 1;
qw{a b c} and 1;
(1) if qw{a b c};
(1) and qw{a b c};
my @a = qw{a b c}, 'a';
qw<a b c>;
my @a = qw<a b c>, 'a';
qw(a b c);
my @a = qw(a b c), 'a';
##-->
qw{a b c};
qw{a b c} if 1;
qw{a b c} and 1;
(1) if qw{a b c};
(1) and qw{a b c};
my @a = qw{a b c}, 'a';
qw<a b c>;
my @a = qw<a b c>, 'a';
qw (a b c);
my @a = qw (a b c), 'a';
