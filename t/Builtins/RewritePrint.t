#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 3;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Builtins::RewritePrint', *DATA );

__DATA__
## name: unchanged
print @_, "\n";
##-->
print @_, "\n";
## name: transform
print FOO "hi";
print OUT "{\n";
print FOO "hi" if 1;
print FOO "hi" and 1;
1 if print FOO "hi";
1 and print FOO "hi";
print $FOO "hi";
print $FOO "hi", "there";
print $local_file $code->(@what);
##-->
FOO.print("hi");
OUT.print("{\n");
FOO.print("hi") if 1;
FOO.print("hi") and 1;
1 if FOO.print("hi");
1 and FOO.print("hi");
$FOO.print("hi");
$FOO.print("hi", "there");
$local_file.print($code->(@what));
