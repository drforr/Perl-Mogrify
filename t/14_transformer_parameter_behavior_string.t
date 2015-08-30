#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::Transformer;
use Perl::ToPerl6::TransformerParameter;

use Test::More tests => 4;

#-----------------------------------------------------------------------------

my $specification;
my $parameter;
my %config;
my $transformer;

$specification =
    {
        name        => 'test',
        description => 'A string parameter for testing',
        behavior    => 'string',
    };


$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, undef, q{no value, no default});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'foobie';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, 'foobie', q{'foobie', no default});


$specification->{default_string} = 'bletch';
delete $config{test};

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, 'bletch', q{no value, default 'bletch'});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'foobie';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, 'foobie', q{'foobie', default 'bletch'});


###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
