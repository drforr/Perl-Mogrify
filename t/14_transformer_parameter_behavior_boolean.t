#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::Transformer;
use Perl::ToPerl6::TransformerParameter;
use Perl::ToPerl6::Utils qw{ :booleans };

use Test::More tests => 9;

#-----------------------------------------------------------------------------

my $specification;
my $parameter;
my %config;
my $transformer;

$specification =
    {
        name        => 'test',
        description => 'A boolean parameter for testing',
        behavior    => 'boolean',
    };


$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
TODO: {
    local $TODO =
        'Need to restore tri-state functionality to Behavior::Boolean.';

    $transformer = Perl::ToPerl6::Transformer->new();
    $parameter->parse_and_validate_config_value($transformer, \%config);
    is($transformer->{_test}, undef, q{no value, no default});
}

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = '1';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $TRUE, q{'1', no default});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $FALSE, q{'0', no default});


$specification->{default_string} = '1';
delete $config{test};

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $TRUE, q{no value, default '1'});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = '1';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $TRUE, q{'1', default '1'});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $FALSE, q{'0', default '1'});


$specification->{default_string} = '0';
delete $config{test};

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $FALSE, q{no value, default '0'});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = '1';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $TRUE, q{'1', default '0'});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, $FALSE, q{'0', default '0'});


###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
