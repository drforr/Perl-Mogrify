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
## name: No variables, case-folding, escapes or braces
qq{Hello, "world"! This (kinda complex) ['no, really?'] should->not be altered.}
qq{`1234567890-=~!#%^&*()_+a-zA-Z[]|;':",./<>?}
##-->
qq{Hello, "world"! This (kinda complex) ['no, really?'] should->not be altered.}
qq{`1234567890-=~!#%^&*()_+a-zA-Z[]|;':",./<>?}
## name: \v is no longer a metacharacter
qq{\v}
qq{\v|\value}
##-->
qq{v}
qq{v|value}
## name: \x{263a} is now \x[263a]
qq{\x{2}}
qq{\x{263a}|\x{10ffff}}
##-->
qq{\x[2]}
qq{\x[263a]|\x[10ffff]}
## name: \x1f is unchanged
qq{\x1f}
qq{\x1f|\x1g|\x}
##-->
qq{\x1f}
qq{\x1f|\x1g|}
## name: \N{U+1234} is now \x[1234]
qq{\N{U+1234}}
qq{\N{U+1234}|foo\N{U+1234}bar}
##-->
qq{\x[1234]}
qq{\x[1234]|foo\x[1234]bar}
## name: \N{LATIN CAPITAL LETTER X} is now \x[LATIN CAPITAL LETTER X1234]
qq{\N{LATIN CAPITAL LETTER X}}
qq{\N{LATIN CAPITAL LETTER X}|foo\N{LATIN CAPITAL LETTER X}bar}
##-->
qq{\c[LATIN CAPITAL LETTER X]}
qq{\c[LATIN CAPITAL LETTER X]|foo\c[LATIN CAPITAL LETTER X]bar}
## name: single octal character
qq{\o17}
qq{\o|\o1|\o8|\o{}|\o{12}|\o{18}}
qq{\0|\017|\018|\08}
##-->
qq{\o17}
qq{\o|\o1|\o8|\o[]|\o[12]|\o[18]}
qq{\0|\017|\018|\08}
## name: simple variables
qq{$a|${a}|$a{a}|$a{'a'}|$a{"a"}}
qq{$a]|[${a}]|[$a{a}]|[$a{'a'}]|[$a{"a"}}
##-->
qq{$a|${a}|$a{a}|$a{'a'}|$a{"a"}}
qq{$a]|[${a}]|[$a{a}]|[$a{'a'}]|[$a{"a"}}
## name: mix backslash and regular
qq{\$a|\${a}|$a{a}|\$a{'a'}|\$a{"a"}}
qq{\$a]|[\${a}]|[$a{a}]|[\$a{'a'}]|[\$a{"a"}}
##-->
qq{\$a|\${a}|$a{a}|\$a{'a'}|\$a{"a"}}
qq{\$a]|[\${a}]|[$a{a}]|[\$a{'a'}]|[\$a{"a"}}
## name: Check that \l,\u and friends aren't escaped inside variables.
qq{$a\l|\l${\ua}\l|\l$a{\La\E}\l|\l$a{\Q'a'\E}\l|\l$a{"a"}}
##-->
qq{$a\l|\l${\ua}\l|\l$a{\La\E}\l|\l$a{\Q'a'\E}\l|\l$a{"a"}}
