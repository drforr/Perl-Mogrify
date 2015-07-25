#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Variables::FormatHashKeys', *DATA );

__DATA__
## name: quote barewords - Doesn't alter sigils.
$a { a }++;
$a -> { a }++;
$a { a }++ if 1;
$a { a }++ and 1;
1 if $a { a }++;
1 and $a { a }++;
$a { 'a' }++;
$a { "a" }++;
##-->
$a { 'a' }++;
$a -> { 'a' }++;
$a { 'a' }++ if 1;
$a { 'a' }++ and 1;
1 if $a { 'a' }++;
1 and $a { 'a' }++;
$a { 'a' }++;
$a { "a" }++;
