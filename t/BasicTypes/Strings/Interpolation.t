#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::Interpolation', *DATA );

### ## name: Special cases
### "${x}";
### qq{${x}};
### "\${x}";
### ##-->
### "{$x}";
### qq{{$x}};
### "\$\{x\}";
### ## name: uninterpolated braces
### "{x";
### print OUT "{\n";
### "x}";
### "{x}";
### "${x";
### ##-->
### "\{x";
### print OUT "\{\n";
### "x\}";
### "\{x\}";
### "$\{x";
### ## name: escaped braces
### "$\{x\}"
### ##-->
### "$\{x\}"
### ## name: hash key
### "$x{a}"
### "$x{a}{b}"
### "$x{a}[1]"
### "$x{'a'}"
### "$x->{'a'}"
### ##-->
### "$x{'a'}"
### "$x{'a'}{'b'}"
### "$x{'a'}[1]"
### "$x{'a'}"
### "$x.{'a'}"
### ## name: array index
### "$x[1]"
### "$x[1]{a}"
### ##-->
### "$x[1]"
### "$x[1]{'a'}"

__DATA__
## name: vertical tab
qq q\vq
##-->
qq qvq
## name: Control character
"\ca|\c{|\c}|\c"
##-->
"\c[0x61]|\c[0x7b]|\c[0x7d]|\c[0x0]"
## name: case-shift single character
"\la|\llama|\l{|\l"
"\ua|\udon|\u{|\u"
##-->
"{lcfirst("a")}|{lcfirst("l")}ama|{|"
"{ucfirst("a")}|{ucfirst("d")}on|{|"
## name: single Unicode character
"\N{U+1234}|\N{ U  + 1234  }|\N{LATIN CAPITAL LETTER X}|"
##-->
"\x[1234]|\x[1234]|\c[LATIN CAPITAL LETTER X]|"
## name: single octal character
"\o|\o1|\o8|\o{}|\o{12}|\o{18}"
"\0|\017|\018|\08"
##-->
"\o|\o1|\o8|\o{}|\o[12]|\o{18}"
"\o[0]|\o[17]|\o[1]8|\o[0]8"
## name: single hex character
"\x|\x1|\xg|\x1f|\x{"
"\x{}|\x{0}|\x{1ffff}"
##-->
"x|\x1|xg|\x1f|x{"
"\x[0]|\x[0]|\x[1ffff]"
## name: lower-case character range
"\L\E|\L\x{1234}\E|\Lfoo\E|\Lfoo"
##-->
"{lc("")}|{lc("\x[1234]")}|{lc("foo")}|{lc("foo")}"
