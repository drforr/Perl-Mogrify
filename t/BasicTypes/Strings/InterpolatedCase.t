#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::InterpolatedCase', *DATA );

#-----------------------------------------------------------------------------
# ensure we return true if this test is loaded by
# 20_transformers.t_without_optional_dependencies.t

1;

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
__DATA__
## name: Braced blocks pass through unaltered
"Hello ${x} {$x} \{$x\}"
##-->
"Hello ${x} {$x} \{$x\}"
## name: lc/uc on literals
"\lax"
qq{\lax}
"\lAx"
"\lR\Elax"
"\l\l\l\lax"
"\l\l\l\lAx"
"\uax"
"\uAx"
"\u\l\l\lax"
"\u\l\l\lAx"
##-->
"{lcfirst("a")}x"
qq{{lcfirst(qq{a})}x}
"{lcfirst("A")}x"
"{lcfirst("R")}lax"
"{lcfirst("a")}x"
"{lcfirst("A")}x"
"{ucfirst("a")}x"
"{ucfirst("A")}x"
"{ucfirst("a")}x"
"{ucfirst("A")}x"
## name: Unnested \L, \U with literals
"\LLOWER"
"\LLOWER'ED"
"\LLOWER\E"
"Start \LLOWER\E End"
"\LLOWER\E\E"
"\LLOWER\E\Uupper"
"\LLOWER\E\Uupper\E"
"Start \LLOWER\E Middle \Uupper\E End"
"\LLOWER\E\Uupper\E\E"
##-->
"{lc("LOWER")}"
"{lc("LOWER'ED")}"
"{lc("LOWER")}"
"Start {lc("LOWER")} End"
"{lc("LOWER")}"
"{lc("LOWER")}{uc("upper")}"
"{lc("LOWER")}{uc("upper")}"
"Start {lc("LOWER")} Middle {uc("upper")} End"
"{lc("LOWER")}{uc("upper")}"
## name: Unnested \L, \U with variables
"\L$x"
"\L$x\E"
"Start \L$x\E End"
"\L$x\E\E"
"\L$x\E\U$y"
"\L$x\E\U$y\E"
"Start \L$x\E Middle \U$y\E End"
"\L$x\E\U$y\E\E"
##-->
"{lc("$x")}"
"{lc("$x")}"
"Start {lc("$x")} End"
"{lc("$x")}"
"{lc("$x")}{uc("$y")}"
"{lc("$x")}{uc("$y")}"
"Start {lc("$x")} Middle {uc("$y")} End"
"{lc("$x")}{uc("$y")}"
## name: Unnested \L, \U with mixed literals and variables
"\Lfoo$x"
"\Lfoo$x\E"
"a\Lfoo$xb"
"a\Lfoo$x\Eb"
##-->
"{lc("foo$x")}"
"{lc("foo$x")}"
"a{lc("foo$xb")}"
"a{lc("foo$x")}b"
## name: Nested constructs, remember that \L\U is illegal as is \L\L
"\LLOWER\Uupper\Enormal\E"
qq{\LL{WER\Uu}per\Enormal\E}
##-->
"{lc("LOWER"~uc("upper")~"normal")}"
qq{{lc(qq{L\{WER}~uc(qq{u\}per})~qq{normal})}}
