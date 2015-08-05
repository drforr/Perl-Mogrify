#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::AddWhitespace', *DATA );

__DATA__
## name: Basic string types
'foo bar';
q{foo bar};
q(foo bar);
qq{foo bar};
qq(foo bar);
##-->
'foo bar';
q{foo bar};
q (foo bar);
qq{foo bar};
qq (foo bar);
