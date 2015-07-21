#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::Interpolation', *DATA );

### ## name: Special cases
### "\N{LATIN CAPITAL LETTER X}";
### "a\N{LATIN CAPITAL LETTER X}b";
### "\x{12ab}";
### "a\x{12ab}b";
### ##-->
### "\c[LATIN CAPITAL LETTER X]";
### "a\c[LATIN CAPITAL LETTER X]b";
### "\x[12ab]";
### "a\x[12ab]b"; ### ## name: interpolation of bracketed variables
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

### ## name: No braces, no alteration.
### "Hello (cruel?) world! $x <= $y[2] + 1"
### ##-->
### "Hello (cruel?) world! $x <= $y[2] + 1"
### ## name: Unicode-related stuff
### "\x{263a}";
### "\o{2637}";
### "Hello world \x{263a}!";
### "Hello world \o{2637}!";
### "\N{LATIN CAPITAL LETTER X}"
### "Hello world \N{LATIN CAPITAL LETTER X}!"
### ##-->
### "\x[263a]";
### "\o[2637]";
### "Hello world \x[263a]!";
### "Hello world \o[2637]!";
### "\c[LATIN CAPITAL LETTER X]"
### "Hello world \c[LATIN CAPITAL LETTER X]!"

__DATA__
## name: vertical tab
qq q\vq
##-->
qq qq
## name: Control character
"\ca|\c{|\c}|\c"
##-->
"\c[0x61]|\c[0x7b]|\c[0x7d]|\c"
## name: case-shift single character
"\la|\llama|\l"
"\ua|\udon|\u"
##-->
"{lcfirst("a")}|{lcfirst("l")}ama|"
"{ucfirst("a")}|{ucfirst("d")}on|"
## name: Unicode character description
"\N{U+1234}|\N{ U  + 1234  }|\N{LATIN CAPITAL LETTER X}|"
##-->
"\x[1234]|\x[1234]|\c[LATIN CAPITAL LETTER X]|"
