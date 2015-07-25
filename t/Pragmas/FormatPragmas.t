#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'Pragmas::FormatPragmas', *DATA );

__DATA__
## name: unchanged
use strict;
use warnings;
use constant FOO => 1;
use base qw( Foo );
##-->


use constant FOO => 1;
use base qw( Foo );
