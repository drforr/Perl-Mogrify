#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 6;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'Variables::FormatSigils', *DATA );

__DATA__
## name: empty assignment
$a = '';
@a = ( );
%a = ( );
##-->
$a = '';
@a = ( );
%a = ( );
## name: basic types
$a = 'a';
$a = [ 0 ];
$a = [ 'a' ];
$a [ 0 ] = 'a';
$a [ 0 ] = 'a' if 1;
$a [ 0 ] = 'a' and 1;
1 if $a [ 0 ] = 'a';
1 and $a [ 0 ] = 'a';
$a { a } = 'a';
$a { 'a' } = 'a';
$a -> [ 0 ] = 'a';
$a -> { a } = 'a';
$a [ 0 ] = 'a';
$a { a } = 'a';
##-->
$a = 'a';
$a = [ 0 ];
$a = [ 'a' ];
@a [ 0 ] = 'a';
@a [ 0 ] = 'a' if 1;
@a [ 0 ] = 'a' and 1;
1 if @a [ 0 ] = 'a';
1 and @a [ 0 ] = 'a';
%a { a } = 'a';
%a { 'a' } = 'a';
$a -> [ 0 ] = 'a';
$a -> { a } = 'a';
@a [ 0 ] = 'a';
%a { a } = 'a';
## name: references
$a = [ 0 ];
$a = [ 'a' ];
$a -> [ 0 ] = 'a';
$a -> { a } = 'a';
##-->
$a = [ 0 ];
$a = [ 'a' ];
$a -> [ 0 ] = 'a';
$a -> { a } = 'a';
## name: slices
$a [ 0, 1 ] = ( 'a', 'b' );
$a { 'a', 'b' } = ( 'a', 'b' );
$a { qw( a b ) } = ( 'a', 'b' );
##-->
@a [ 0, 1 ] = ( 'a', 'b' );
%a { 'a', 'b' } = ( 'a', 'b' );
%a { qw( a b ) } = ( 'a', 'b' );
## name: last index
$#x = 1;
if( $icom > $#Commands ){ }
$Defined{$#Commands} = " #$expr";
##-->
@x.end = 1;
if( $icom > @Commands.end ){ }
%Defined{@Commands.end} = " #$expr";
