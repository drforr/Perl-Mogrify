#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 7;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::FormatMapGreps', *DATA );

__DATA__
## name: blocks in void
map { $_++ } @x;
map { $_++ } @x if 1;
map { $_++ } @x and 1;
1 if map { $_++ } @x;
1 and map { $_++ } @x;
map { $_++ } @x, @y;
map { $_++ } ();
grep { $_++ } @x;
grep { $_++ } @x, @y;
grep { $_++ } ();
##-->
map { $_++ }, @x;
map { $_++ }, @x if 1;
map { $_++ }, @x and 1;
1 if map { $_++ }, @x;
1 and map { $_++ }, @x;
map { $_++ }, @x, @y;
map { $_++ }, ();
grep { $_++ }, @x;
grep { $_++ }, @x, @y;
grep { $_++ }, ();
## name: blocks in expression
my @y = map { $_++ } @x;
my @y = map { $_++ } @x, @y;
my @y = map { $_++ } ();
my @y = grep { $_++ } @x;
my @y = grep { $_++ } @x, @y;
my @y = grep { $_++ } ();
##-->
my @y = map { $_++ }, @x;
my @y = map { $_++ }, @x, @y;
my @y = map { $_++ }, ();
my @y = grep { $_++ }, @x;
my @y = grep { $_++ }, @x, @y;
my @y = grep { $_++ }, ();
## name: compound blocks in void
map { $_++, 1; 3 } @x;
map { $_++, 1; 3 } @x, @y;
map { $_++, 1; 3 } ();
grep { $_++, 1; 3 } @x;
grep { $_++, 1; 3 } @x, @y;
grep { $_++, 1; 3 } ();
##-->
map { $_++, 1; 3 }, @x;
map { $_++, 1; 3 }, @x, @y;
map { $_++, 1; 3 }, ();
grep { $_++, 1; 3 }, @x;
grep { $_++, 1; 3 }, @x, @y;
grep { $_++, 1; 3 }, ();
## name: compound blocks in expression
my @y = map { $_++, 1; 3 } @x;
my @y = map { $_++, 1; 3 } @x, @y;
my @y = map { $_++, 1; 3 } ();
my @y = grep { $_++, 1; 3 } @x;
my @y = grep { $_++, 1; 3 } @x, @y;
my @y = grep { $_++, 1; 3 } ();
##-->
my @y = map { $_++, 1; 3 }, @x;
my @y = map { $_++, 1; 3 }, @x, @y;
my @y = map { $_++, 1; 3 }, ();
my @y = grep { $_++, 1; 3 }, @x;
my @y = grep { $_++, 1; 3 }, @x, @y;
my @y = grep { $_++, 1; 3 }, ();
## name: multiple expressions
map { } grep { } @a;
map { } grep { } ();
##-->
map { }, grep { }, @a;
map { }, grep { }, ();
## name: transform
map /x/, @x;
map /x/, @x, @y;
map /x/, ();
map /x/, (), ();
grep /x/, @x;
grep !$x, @x;
grep !$x, ();
##-->
map {/x/}, @x;
map {/x/}, @x, @y;
map {/x/}, ();
map {/x/}, (), ();
grep {/x/}, @x;
grep {!$x}, @x;
grep {!$x}, ();
