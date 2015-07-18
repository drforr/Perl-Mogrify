#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Mogrify::UserProfile;

use Test::More tests => 41;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

# Create profile from hash

{
    my %policy_params = (min_elements => 4);
    my %profile_hash = ( '-BasicTypes::Strings::FormatShellStrings' => {},
        '-Variables::FormatHashKeys' => \%policy_params );

    my $up = Perl::Mogrify::UserProfile->new( -profile => \%profile_hash );

    # Using short policy names
SKIP: {
  skip "XXX Need to restore this eventually", 1;
    is(
        $up->policy_is_enabled('Variables::FormatHashKeys'),
        1,
        'Variables::FormatHashKeys is enabled.',
    );
}
    is(
        $up->policy_is_disabled('Variables::FormatHashKeys'),
        1,
        'Variables::FormatHashKeys is disabled.',
    );
SKIP: {
  skip "XXX Need to restore this eventually", 1;
    is_deeply(
        $up->raw_policy_params('Variables::FormatHashKeys'),
        \%policy_params,
        'Variables::FormatHashKeys got the correct configuration.',
    );
}

SKIP: {
  skip "XXX Need to restore these eventually", 2;
    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        1,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::NamingConventions::Capitalization'),
        1,
        'Perl::Mogrify::Transformer::NamingConventions::Capitalization is disabled.',
    );
}
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        \%policy_params,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Bogus'),
        {},
        q<Bogus Transformer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Create profile from array

{
    my %policy_params = (min_elements => 4);
    my @profile_array = ( q{ [-NamingConventions::Capitalization] },
                          q{ [Variables::FormatHashKeys]           },
                          q{ min_elements = 4                         },
    );


    my $up = Perl::Mogrify::UserProfile->new( -profile => \@profile_array );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Variables::FormatHashKeys'),
        1,
        'Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Variables::FormatHashKeys'),
        \%policy_params,
        'Variables::FormatHashKeys got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        1,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::NamingConventions::Capitalization'),
        1,
        'Perl::Mogrify::Transformer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        \%policy_params,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Bogus'),
        {},
        q<Bogus Transformer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Create profile from string

{
    my %policy_params = (min_elements => 4);
    my $profile_string = <<'END_PROFILE';
[-NamingConventions::Capitalization]
[Variables::FormatHashKeys]
min_elements = 4
END_PROFILE

    my $up = Perl::Mogrify::UserProfile->new( -profile => \$profile_string );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Variables::FormatHashKeys'),
        1,
        'Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Variables::FormatHashKeys'),
        \%policy_params,
        'Variables::FormatHashKeys got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        1,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::NamingConventions::Capitalization'),
        1,
        'Perl::Mogrify::Transformer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        \%policy_params,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Bogus'),
        {},
        q<Bogus Transformer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Test long policy names

{
    my %policy_params = (min_elements => 4);
    my $long_profile_string = <<'END_PROFILE';
[-Perl::Mogrify::Transformer::NamingConventions::Capitalization]
[Perl::Mogrify::Transformer::Variables::FormatHashKeys]
min_elements = 4
END_PROFILE

    my $up = Perl::Mogrify::UserProfile->new( -profile => \$long_profile_string );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Variables::FormatHashKeys'),
        1,
        'Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Variables::FormatHashKeys'),
        \%policy_params,
        'Variables::FormatHashKeys got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        1,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::NamingConventions::Capitalization'),
        1,
        'Perl::Mogrify::Transformer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Variables::FormatHashKeys'),
        \%policy_params,
        'Perl::Mogrify::Transformer::Variables::FormatHashKeys got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Mogrify::Transformer::Bogus'),
        q{},
        q<Bogus Transformer isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Mogrify::Transformer::Bogus'),
        {},
        q<Bogus Transformer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $code_ref = sub { return };
    eval { Perl::Mogrify::UserProfile->new( -profile => $code_ref ) };
    like(
        $EVAL_ERROR,
        qr/Can't [ ] load [ ] UserProfile/xms,
        'Invalid profile type',
    );

    eval { Perl::Mogrify::UserProfile->new( -profile => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/Could [ ] not [ ] parse [ ] profile [ ] "bogus"/xms,
        'Invalid profile path',
    );

    my $invalid_syntax = '[Foo::Bar'; # Missing "]"
    eval { Perl::Mogrify::UserProfile->new( -profile => \$invalid_syntax ) };
    like(
        $EVAL_ERROR,
        qr/Syntax [ ] error [ ] at [ ] line/xms,
        'Invalid profile syntax',
    );

    $invalid_syntax = 'severity 2'; # Missing "="
    eval { Perl::Mogrify::UserProfile->new( -profile => \$invalid_syntax ) };
    like(
        $EVAL_ERROR,
        qr/Syntax [ ] error [ ] at [ ] line/xms,
        'Invalid profile syntax',
    );

}

#-----------------------------------------------------------------------------
# Test profile finding

{
    my $expected = local $ENV{PERLMOGRIFY} = 'foo';
    my $got = Perl::Mogrify::UserProfile::_find_profile_path();
    is( $got, $expected, 'PERLMOGRIFY environment variable');
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/10_userprofile.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
