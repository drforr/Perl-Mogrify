#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Pragmas::RewritePragmas', *DATA );

__DATA__
## name: unchanged
use strict;
use warnings;
use constant FOO => 1;
use base qw( Foo );
##-->


use constant FOO => 1;
use base qw( Foo );
