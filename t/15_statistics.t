#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::Statistics;
use Perl::ToPerl6::TestUtils;

use Test::More tests => 18;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------

my $package = 'Perl::ToPerl6::Statistics';

my @methods = qw(
    average_sub_mccabe
    lines
    modules
    new
    statements
    subs
    total_transformations
    transformations_by_transformer
    transformations_by_severity
    statements_other_than_subs
    transformations_per_file
    transformations_per_statement
    transformations_per_line_of_code
);

for my $method ( @methods ) {
    can_ok( $package, $method );
}

#-----------------------------------------------------------------------------

my $code = <<'END_PERL';
package Foo;

use My::Module;
$this = $that if $condition;
sub foo { return @list unless $condition };
END_PERL

#-----------------------------------------------------------------------------

my $profile = { '-Arrays::FormatArrayQws' => {} };
my $mogrify =
    Perl::ToPerl6->new(
        -severity => 1,
        -profile => $profile,
        -theme => 'core',
    );
my @transformations = $mogrify->transform( \$code );

#print @transformations;
#exit;

my %expected_stats = (
    average_sub_mccabe            => 2,
    lines                         => 5,
    modules                       => 1,
    statements                    => 6,
    statements_other_than_subs    => 5,
    subs                          => 1,
    total_transformations              => 7,
    transformations_per_file           => 7,
    transformations_per_line_of_code   => 1.4, # 7 transformations / 5 lines
    transformations_per_statement      => 1.4, # 7 transformations / 5 lines
);

my $stats = $mogrify->statistics();
isa_ok($stats, $package);

SKIP: {
  skip "XXX Need to restore this eventually", 4;
while ( my($method, $expected) = each %expected_stats) {
    is( $stats->$method, $expected, "Statistics: $method");
}
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/15_statistics.t_without_optional_dependencies.t
1;

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
