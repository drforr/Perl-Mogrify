#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Regexes::SwapModifiers', *DATA );

__DATA__
## name: match transformed
/foo/
m/foo/
m<foo>
m/foo/i
m/foo/i if 1
m/foo/i and 1
1 if m/foo/i
1 and m/foo/i
m<foo>i
##-->
m:P5/foo/
m:P5/foo/
m:P5<foo>
m:i:P5/foo/
m:i:P5/foo/ if 1
m:i:P5/foo/ and 1
1 if m:i:P5/foo/
1 and m:i:P5/foo/
m:i:P5<foo>
## name: drop unused modifiers
m/foo/gs
s/foo/bar/gs
##-->
m:P5/foo/
s:P5/foo/bar/
## name: substitute
s/foo/bar/
s{foo}<bar>
s(foo)(bar)
s/foo/bar/i
s{foo}<bar>i
s(foo)(bar)i
##-->
s:P5/foo/bar/
s:P5{foo}<bar>
s:P5(foo)(bar)
s:i:P5/foo/bar/
s:i:P5{foo}<bar>
s:i:P5(foo)(bar)
## name: regression
s/Parse::RecDescent/$runtime_package/gs;
##-->
s:P5/Parse::RecDescent/$runtime_package/;
