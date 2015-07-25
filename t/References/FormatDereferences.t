#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'References::FormatDereferences', *DATA );

__DATA__
## name: unchanged
%$foo;
%$foo if 1;
%$foo and 1;
1 if %$foo;
1 and %$foo;
@$foo;
%{ $foo };
@{ $foo };
$#{ $foo };
##-->
%$foo;
%$foo if 1;
%$foo and 1;
1 if %$foo;
1 and %$foo;
@$foo;
%( $foo );
@( $foo );
@( $foo ).end;
