#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Variables::ReplaceNegativeIndex', *DATA );

__DATA__
## name: Mixture
$a[0]
$a[1]
$a[-2]
$a{x}[-2]
$a[$x-2]
##-->
$a[0]
$a[1]
$a[*-2]
$a{x}[*-2]
$a[$x-2]
## name: regression
unless $self->{items}[-1]->describe =~ /<score/;
$a[-0x23]
##-->
unless $self->{items}[*-1]->describe =~ /<score/;
$a[*-0x23]
