#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Variables::FormatSpecialVariables', *DATA );

#-----------------------------------------------------------------------------
__DATA__
## name: transform
## I'm not sure any special variables *didn't* get renamed...
print STDOUT;
print STDOUT if 1;
print STDOUT and 1;
1 if print STDOUT;
1 and print STDOUT;
print $`;
print $&;
print @+;
print $1;
##-->
## I'm not sure any special variables *didn't* get renamed...
print $*OUT;
print $*OUT if 1;
print $*OUT and 1;
1 if print $*OUT;
1 and print $*OUT;
print $/.prematch;
print ~$/;
print (map {.from},$/[*]);
print $0;
