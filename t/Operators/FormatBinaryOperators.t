#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::Mogrify::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Operators::FormatBinaryOperators', *DATA );

__DATA__
## name: transformed
1 + 1;
1 + 1 if 1;
1 + 1 and 1;
1 if 1 + 1;
1 and 1 + 1;
'1' . '1';
Foo->new();
Foo -> new();
##-->
1 + 1;
1 + 1 if 1;
1 + 1 and 1;
1 if 1 + 1;
1 and 1 + 1;
'1' ~ '1';
Foo.new();
Foo . new();
