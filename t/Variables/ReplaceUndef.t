#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Variables::ReplaceUndef', *DATA );

#-----------------------------------------------------------------------------
__DATA__
## name: Replace undef
undef = 1;
$x = undef;
say undef;
foo(undef);
foo 1,undef;
undef(3);
##-->
undef = 1;
$x = Any;
say Any;
foo(Any);
foo 1,Any;
undef(3);
