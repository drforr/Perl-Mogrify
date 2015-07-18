#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Regexes::SwapModifiers', *DATA );

__DATA__
## name match transformed
## parms {}
## failures 0
## cut
/foo/
m/foo/
m<foo>
m/foo/i
m/foo/i if 1
m/foo/i and 1
1 if m/foo/i
1 and m/foo/i
m<foo>i
m<foo>gi
#-->
/foo/
m/foo/
m<foo>
m:i/foo/
m:i/foo/ if 1
m:i/foo/ and 1
1 if m:i/foo/
1 and m:i/foo/
m:i<foo>
m:gi<foo>
## name: substitute
s/foo/bar/
s{foo}<bar>
s(foo)(bar)
s/foo/bar/i
s{foo}<bar>i
s(foo)(bar)i
##-->
s/foo/bar/
s{foo}<bar>
s(foo)(bar)
s:i/foo/bar/
s:i{foo}<bar>
s:i(foo)(bar)
