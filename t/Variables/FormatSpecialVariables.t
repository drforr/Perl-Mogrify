#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Variables::FormatSpecialVariables', *DATA );

#-----------------------------------------------------------------------------
__DATA__
## name: transform
print STDOUT;
print STDOUT if 1;
print STDOUT and 1;
1 if print STDOUT;
1 and print STDOUT;
print $`;
print $&;
print @+;
1 unless @ARGV == 1;
##-->
print $*OUT;
print $*OUT if 1;
print $*OUT and 1;
1 if print $*OUT;
1 and print $*OUT;
print $/.prematch;
print ~$/;
print (map {.from},$/[*]);
1 unless @*ARGS == 1;
