## name Unaltered
## parms {}
## failures 0
## cut
"Hello (cruel?) world! $x <= $y[2] + 1"
#-->
"Hello (cruel?) world! $x <= $y[2] + 1"
## name Unicode character names
## parms {}
## failures 0
## cut
"\N{LATIN CAPITAL LETTER X}";
#-->
"\c[LATIN CAPITAL LETTER X]";
## name interpolation of bracketed variables
## parms {}
## failures 0
## cut
"${x}";
"\${x}";
#-->
"{$x}";
"\$\{x\}";
## name uninterpolated braces
## parms {}
## failures 0
## cut
"{x";
"x}";
"${x";
#-->
"\{x";
"x\}";
"$\{x";
