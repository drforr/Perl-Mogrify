#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 12;

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

transform_ok( 'BasicTypes::Strings::Interpolation', *DATA );

__DATA__
## name: No variables, case-folding, escapes, pointy blocks or braces
qq{Hello, "world"! This (kinda complex) ['no, really?'] should-be altered.}
##-->
qq{Hello, "world"! This \(kinda complex\) ['no, really?'] should-be altered.}
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
qq{$a|${a}|$a{a}|$a{'a'}|$a{"a"}|$a->{a}|$a->{'a'}|$a->{"a"}}
qq{$a]|[${a}]|[$a{a}]|[$a{'a'}]|[$a{"a"}]|[$a->{a}]|[$a->{'a'}]|[$a->{"a"}}
##-->
qq{$a|{$a}|$a{qq{a}}|$a{'a'}|$a{"a"}|$a.{qq{a}}|$a.{'a'}|$a.{"a"}}
qq{$a]|[{$a}]|[$a{qq{a}}]|[$a{'a'}]|[$a{"a"}]|[$a.{qq{a}}]|[$a.{'a'}]|[$a.{"a"}}
## name: variable, interrupted
qq{${a
}}
qq{$a{a
}}
qq{$a{'a'
}}
##-->
qq{{$a
}}
qq{$a{qq{a}
}}
qq{$a{'a'
}}
## name: mix backslash and regular
qq{\$a|\${a}|$a{a}|\$a{'a'}|\$a{"a"}|$a->{a}}
qq{\$a]|[\${a}]|[$a{a}]|[\$a{'a'}]|[\$a{"a"}]|[$a->{'a'}}
##-->
qq{\$a|\$\{a\}|$a{qq{a}}|\$a\{'a'\}|\$a\{"a"\}|$a.{qq{a}}}
qq{\$a]|[\$\{a\}]|[$a{qq{a}}]|[\$a\{'a'\}]|[\$a\{"a"\}]|[$a.{'a'}}
## name: regressions
"$weeks @{[$weeks == 1 ? q(week) : q(weeks)]}"
" @ %$f/s (n=$n)"
is( "$@$!$,$/$\$^W", "1\n0", 'DB::save() should reset punctuation vars' )
"my \$E; { local \$@; }"
is("\N{NULL}", "\c@", 'Verify "\N{NULL}" eq "\c@"')
"${$_[0]}"
"sections=s@"
"@[\n"
"_alternation_${impcount}_of_production_${prodcount}_of_rule_$self->{name}"
"Incomplete <$next->{type}op:...>."
"Incorrect token specification: \"$@\""
"\<leftop='$name(s?)': $name $2 $name\>(s?) "
"$code$argcode($1..)"
"\<leftop='$name(..$1)': $name $2 $name\>(..$1) "
#"push \@{\$thisparser->{deferred}}, sub $code;"
##-->
"$weeks @{[$weeks == 1 ? q(week) : q(weeks)]}"
" @ %$f/s \(n=$n\)"
is( "$@$!$,$/$\$^W", "1\n0", 'DB::save() should reset punctuation vars' )
"my \$E; \{ local \$@; \}"
is("\c[NULL]", "\c@", 'Verify "\N{NULL}" eq "\c@"')
"${$_[0]}"
"sections=s@"
"@[\n"
"_alternation_{$impcount}_of_production_{$prodcount}_of_rule_$self.{"name"}"
"Incomplete \<$next.{"type"}op:...\>."
"Incorrect token specification: \"$@\""
"\<leftop='$name\(s?\)': $name $2 $name\>\(s?\) "
"$code$argcode\($1..\)"
"\<leftop='$name\(..$1\)': $name $2 $name\>\(..$1\) "
#"push \@{\$thisparser->{deferred}}, sub $code;"
