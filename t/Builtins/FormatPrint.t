#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Builtins::FormatPrint', *DATA );

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
##-->
FOO.print("hi");
OUT.print("{\n");
FOO.print("hi") if 1;
FOO.print("hi") and 1;
1 if FOO.print("hi");
1 and FOO.print("hi");
$FOO.print("hi");
$FOO.print("hi", "there");
