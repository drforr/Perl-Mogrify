#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 3;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Regexes::StandardizeDelimiters', *DATA );

__DATA__
## name: match transformed
/foo/
m/foo/
m#foo#
m gfoog
m gfoog if 1
m gfoog and 1
1 if m gfoog
1 and m gfoog
m f\foof
m f\f/oof
##-->
/foo/
m/foo/
m/foo/
m/foo/
m/foo/ if 1
m/foo/ and 1
1 if m/foo/
1 and m/foo/
m/\foo/
m/\f\/oo/
## name: match with modifiers
m mo\mma
s b\bookkeebpber
##-->
m/o\m/a
s/\bookkee/p/er
