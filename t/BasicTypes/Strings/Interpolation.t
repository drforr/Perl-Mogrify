#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;
### name: Check single layer of casefolding
#qq<\FLOWER\E\U$upper\E\Q***\E>
#qq<xx\FLOWER\Exx>
#qq<\LLOWER>
###-->
#qq<{lc(qq<LOWER>)}{tc(qq<$upper>)}{quotemeta(qq<***>)}>
#qq<xx{lc(qq<LOWER>)}xx>
#qq<{lc(qq<LOWER>)}>
### name: Multiple tokens casefolded
#qq<\Flower$xxx\E>
###-->
#qq<{lc(qq<lower$xxx>)}>
### name: Nested casefold tokens
#qq<\LLOWER\Uupper\ELOWER\E>
###-->
#qq<{lc(qq<LOWER>)~tc(qq<upper>)~qq<LOWER>}>
### name: Nested casefold tokens
#qq{\LLOWER\Uupper\ELOWER\E}
###-->
#qq{{lc(qq{LOWER})~tc(qq{upper})~qq{LOWER}}}

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::Interpolation', *DATA );

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
qq{\$a|\$\{a\}|$a{a}|\$a\{'a'\}|\$a\{"a"\}}
qq{\$a]|[\$\{a\}]|[$a{a}]|[\$a\{'a'\}]|[\$a\{"a"\}}
## name: Check that \l,\u and friends aren't escaped inside variables.
qq{$a\l|\l${\ua}\l|\l$a{\La\E}\l|\l$a{\Q'a'\E}\l|\l$a{"a"}}
##-->
qq{$a\l|\l${\ua}\l|\l$a{\La\E}\l|\l$a{\Q'a'\E}\l|\l$a{"a"}}
## name: regressions
return "$weeks @{[$weeks == 1 ? q(week) : q(weeks)]}";
$s .= sprintf(" @ %$f/s (n=$n)",$n/($elapsed)) if $n && $elapsed;
is( "$@$!$,$/$\$^W", "1\n0", 'DB::save() should reset punctuation vars' );
"my \$E; { local \$@; }"
is("\N{NULL}", "\c@", 'Verify "\N{NULL}" eq "\c@"');
sub stringify { "${$_[0]}" }
##-->
return "$weeks @{[$weeks == 1 ? q(week) : q(weeks)]}";
$s .= sprintf(" @ %$f/s (n=$n)",$n/($elapsed)) if $n && $elapsed;
is( "$@$!$,$/$\$^W", "1\n0", 'DB::save() should reset punctuation vars' );
"my \$E; \{ local \$@; \}"
is("\c[NULL]", "\c@", 'Verify "\N{NULL}" eq "\c@"');
sub stringify { "${$_[0]}" }
