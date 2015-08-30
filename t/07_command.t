#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Carp qw< confess >;

use File::Spec;

use Perl::ToPerl6::Command qw< run >;
use Perl::ToPerl6::Utils qw< :characters >;

use Test::More tests => 57;

#-----------------------------------------------------------------------------

local @ARGV = ();
my $message;
my %options = ();

#-----------------------------------------------------------------------------

local @ARGV = qw(-1 -2 -3 -4 -5);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);

local @ARGV = qw(-5 -3 -4 -1 -2);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);

local @ARGV = qw();
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, undef, 'no arguments');

local @ARGV = qw(-2 -3 -necessity 4);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 4, $message);

local @ARGV = qw(-necessity 2 -3 -4);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 2, $message);

local @ARGV = qw(--necessity=2 -3 -4);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 2, $message);

local @ARGV = qw(-cruel);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 'cruel', $message);

local @ARGV = qw(-cruel --necessity=1 );
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);

local @ARGV = qw(-stern --necessity=1 -2);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);

local @ARGV = qw(-stern -necessity 1 -2);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-top);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);
is( $options{-top}, 20, $message);

local @ARGV = qw(-top 10);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 1, $message);
is( $options{-top}, 10, $message);

local @ARGV = qw(-necessity 4 -top);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 4, $message);
is( $options{-top}, 20, $message);

local @ARGV = qw(-necessity 4 -top 10);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 4, $message);
is( $options{-top}, 10, $message);

local @ARGV = qw(-necessity 5 -2 -top 5);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-necessity}, 5, $message);
is( $options{-top}, 5, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-noprofile);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-profile}, q{}, $message);

local @ARGV = qw(-profile foo);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-profile}, 'foo', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-single-transformer nowarnings);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{'-single-transformer'}, 'nowarnings', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-verbose 2);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-verbose}, 2, $message);

local @ARGV = qw(-verbose %l:%c:%m);
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-verbose}, '%l:%c:%m', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-statistics);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-statistics}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-statistics-only);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{'-statistics-only'}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-quiet);
$message = "@ARGV";
%options = Perl::ToPerl6::Command::_get_options();
is( $options{-quiet}, 1, $message);


#-----------------------------------------------------------------------------

local @ARGV = qw(-pager foo);
$message = "@ARGV";
%options = eval { Perl::ToPerl6::Command::_get_options() };
is( $options{-pager}, 'foo', $message );


#-----------------------------------------------------------------------------

foreach my $necessity ([qw{
    -color-necessity-highest
    -colour-necessity-highest
    -color-necessity-5
    -colour-necessity-5
    }],
    [qw{
    -color-necessity-high
    -colour-necessity-high
    -color-necessity-4
    -colour-necessity-4
    }],
    [qw{
    -color-necessity-medium
    -colour-necessity-medium
    -color-necessity-3
    -colour-necessity-3
    }],
    [qw{
    -color-necessity-low
    -colour-necessity-low
    -color-necessity-2
    -colour-necessity-2
    }],
    [qw{
    -color-necessity-lowest
    -colour-necessity-lowest
    -color-necessity-1
    -colour-necessity-1
    }],
) {
    my $canonical = $necessity->[0];
    foreach my $opt (@{ $necessity }) {
        local @ARGV = ($opt => 'cyan');
        $message = "@ARGV";
        %options = eval { Perl::ToPerl6::Command::_get_options() };
        is( $options{$canonical}, 'cyan', $message );
    }
}


#-----------------------------------------------------------------------------
# Intercept pod2usage so we can test invalid options and special switches

{
    no warnings qw(redefine once);
    local *Perl::ToPerl6::Command::pod2usage =
        sub { my %args = @_; confess $args{-message} || q{} };

    local @ARGV = qw( -help );
    eval { Perl::ToPerl6::Command::_get_options() };
    ok( $EVAL_ERROR, '-help option' );

    local @ARGV = qw( -options );
    eval { Perl::ToPerl6::Command::_get_options() };
    ok( $EVAL_ERROR, '-options option' );

    local @ARGV = qw( -man );
    eval { Perl::ToPerl6::Command::_get_options() };
    ok( $EVAL_ERROR, '-man option' );

    local @ARGV = qw( -noprofile -profile foo );
    eval { Perl::ToPerl6::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/-noprofile [ ] with [ ] -profile/xms,
        '-noprofile with -profile',
    );

    local @ARGV = qw( -verbose bogus );
    eval { Perl::ToPerl6::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/looks [ ] odd/xms,
        'Invalid -verbose option',
    );

    local @ARGV = qw( -top -9 );
    eval { Perl::ToPerl6::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/is [ ] negative/xms,
        'Negative -verbose option',
    );

    local @ARGV = qw( -necessity 0 );
    eval { Perl::ToPerl6::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/out [ ] of [ ] range/xms,
        '-necessity too small',
    );

    local @ARGV = qw( -necessity 6 );
    eval { Perl::ToPerl6::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/out [ ] of [ ] range/xms,
        '-necessity too large',
    );
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/07_command.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
