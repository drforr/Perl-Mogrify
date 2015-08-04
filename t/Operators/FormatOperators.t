#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Operators::FormatOperators', *DATA );

__DATA__
## name: whitespace addition
say 1<1;
say 1<=1;
say 1<=>1;
##-->
say 1 <1;
say 1 <=1;
say 1 <=>1;
## name: Unary operators
~32;
~32 if 1;
~32 and 1;
1 if ~32;
1 and ~32;
!$x;
##-->
+^32;
+^32 if 1;
+^32 and 1;
1 if +^32;
1 and +^32;
?^$x;
## name: Binary operators
1 + 1;
1 + 1 if 1;
1 + 1 and 1;
1 if 1 + 1;
1 and 1 + 1;
'1' . '1';
Foo->new();
Foo -> new();
$rule->{'foo'};
$rule -> {'foo'};
##-->
1 + 1;
1 + 1 if 1;
1 + 1 and 1;
1 if 1 + 1;
1 and 1 + 1;
'1' ~ '1';
Foo.new();
Foo.new();
$rule.{'foo'};
$rule.{'foo'};
## name: ternary
$x = $y > 1 ? 0 : 1;
$x = $y > 1 ? 0 : 1 if 1;
$x = $y > 1 ? 0 : 1 and 1;
1 if $x = $y > 1 ? 0 : 1;
1 and $x = $y > 1 ? 0 : 1;
##-->
$x = $y > 1 ?? 0 !! 1;
$x = $y > 1 ?? 0 !! 1 if 1;
$x = $y > 1 ?? 0 !! 1 and 1;
1 if $x = $y > 1 ?? 0 !! 1;
1 and $x = $y > 1 ?? 0 !! 1;
## name: regression
eval { @yaml = $code->($local_file); };
##-->
eval { @yaml = $code.($local_file); };
