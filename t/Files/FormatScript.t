#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Files::FormatScript', *DATA );

__DATA__
## name: transform
#!perl
##-->
#!perl
use v6;
