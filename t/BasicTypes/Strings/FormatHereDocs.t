#!perl

use 5.006001;

use strict;
use warnings;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

transform_ok( 'BasicTypes::Strings::FormatHereDocs', *DATA );

__DATA__
## name: transform
<<EOF;
EOF
<<EOF if 1;
EOF
<<EOF and 1;
EOF
1 if <<EOF;
EOF
1 and <<EOF;
EOF
##-->
q:to/EOF/;
EOF
q:to/EOF/ if 1;
EOF
q:to/EOF/ and 1;
EOF
1 if q:to/EOF/;
EOF
1 and q:to/EOF/;
EOF
