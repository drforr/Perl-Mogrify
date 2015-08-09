#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::Transformer;
use Perl::ToPerl6::TransformerParameter;

use Test::More tests => 24;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

my $specification;
my $parameter;
my %config;
my $transformer;

$specification =
    {
        name        => 'test',
        description => 'An enumeration parameter for testing',
        behavior    => 'enumeration',
    };


eval { $parameter = Perl::ToPerl6::TransformerParameter->new($specification); };
like(
    $EVAL_ERROR,
    qr/\b enumeration_values \b/xms,
    'exception thrown for missing enumeration_values'
);

$specification->{enumeration_values} = 'cranberries';
eval { $parameter = Perl::ToPerl6::TransformerParameter->new($specification); };
like(
    $EVAL_ERROR,
    qr/\b enumeration_values \b/xms,
    'exception thrown for enumeration_values not being an array reference'
);

$specification->{enumeration_values} = [ ];
eval { $parameter = Perl::ToPerl6::TransformerParameter->new($specification); };
like(
    $EVAL_ERROR,
    qr/\b enumeration_values \b/xms,
    'exception thrown for enumeration_values not having at least two elements'
);

$specification->{enumeration_values} = [ qw{ cranberries } ];
eval { $parameter = Perl::ToPerl6::TransformerParameter->new($specification); };
like(
    $EVAL_ERROR,
    qr/\b enumeration_values \b/xms,
    'exception thrown for enumeration_values not having at least two elements'
);


$specification->{enumeration_values} = [ qw{ mercury gemini apollo } ];

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, undef, q{no value, no default});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'gemini';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, 'gemini', q{'gemini', no default});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'easter_bunny';
eval {$parameter->parse_and_validate_config_value($transformer, \%config); };
ok($EVAL_ERROR, q{invalid value});

$specification->{default_string} = 'apollo';
delete $config{test};

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, 'apollo', q{no value, default 'apollo'});

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'gemini';
$parameter->parse_and_validate_config_value($transformer, \%config);
is($transformer->{_test}, 'gemini', q{'gemini', default 'apollo'});


delete $specification->{default_string};
$specification->{enumeration_values} = [ qw{ moore gaiman ellis miller } ];
$specification->{enumeration_allow_multiple_values} = 1;
delete $config{test};

my $values;

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
$values = $transformer->{_test};
is( scalar( keys %{$values} ), 0, q{no value, no default} );

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'moore';
$parameter->parse_and_validate_config_value($transformer, \%config);
$values = $transformer->{_test};
is( scalar( keys %{$values} ), 1, q{'moore', no default} );
ok( $values->{moore}, q{'moore', no default} );

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'gaiman miller';
$parameter->parse_and_validate_config_value($transformer, \%config);
$values = $transformer->{_test};
is( scalar( keys %{$values} ), 2, q{'gaiman miller', no default} );
ok( $values->{gaiman}, q{'gaiman miller', no default} );
ok( $values->{miller}, q{'gaiman miller', no default} );

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'leeb';
eval {$parameter->parse_and_validate_config_value($transformer, \%config); };
ok($EVAL_ERROR, q{invalid value});

$specification->{default_string} = 'ellis miller';
delete $config{test};

$parameter = Perl::ToPerl6::TransformerParameter->new($specification);
$transformer = Perl::ToPerl6::Transformer->new();
$parameter->parse_and_validate_config_value($transformer, \%config);
$values = $transformer->{_test};
is( scalar( keys %{$values} ), 2, q{no value, default 'ellis miller'} );
ok( $values->{ellis}, q{no value, default 'ellis miller'} );
ok( $values->{miller}, q{no value, default 'ellis miller'} );

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'moore';
$parameter->parse_and_validate_config_value($transformer, \%config);
$values = $transformer->{_test};
is( scalar( keys %{$values} ), 1, q{'moore', default 'ellis miller'} );
ok( $values->{moore}, q{'moore', default 'ellis miller'} );

$transformer = Perl::ToPerl6::Transformer->new();
$config{test} = 'gaiman miller';
$parameter->parse_and_validate_config_value($transformer, \%config);
$values = $transformer->{_test};
is( scalar( keys %{$values} ), 2, q{'gaiman miller', default 'ellis miller'} );
ok( $values->{gaiman}, q{'gaiman miller', default 'ellis miller'} );
ok( $values->{miller}, q{'gaiman miller', default 'ellis miller'} );

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
