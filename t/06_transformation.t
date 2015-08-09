#!perl

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Basename qw< basename >;
use File::Spec::Functions qw< catdir catfile >;
use PPI::Document q< >;
use PPI::Document::File q< >;

use Perl::ToPerl6::Utils qw< :characters >;
use Perl::ToPerl6::Transformation q< >;

use Test::More tests => 67;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

use lib catdir( qw< t 06_transformation.d lib > );

use TransformationTest;   # this is solely to test the import() method; has diagnostics
use TransformationTest2;  # this is solely to test the import() method; no diagnostics

#-----------------------------------------------------------------------------
#  method tests

{
    can_ok('Perl::ToPerl6::Transformation', 'sort_by_location');
    can_ok('Perl::ToPerl6::Transformation', 'sort_by_severity');
    can_ok('Perl::ToPerl6::Transformation', 'new');
    can_ok('Perl::ToPerl6::Transformation', 'location');
    can_ok('Perl::ToPerl6::Transformation', 'diagnostics');
    can_ok('Perl::ToPerl6::Transformation', 'description');
    can_ok('Perl::ToPerl6::Transformation', 'explanation');
    can_ok('Perl::ToPerl6::Transformation', 'filename');
    can_ok('Perl::ToPerl6::Transformation', 'source');
    can_ok('Perl::ToPerl6::Transformation', 'transformer');
    can_ok('Perl::ToPerl6::Transformation', 'get_format');
    can_ok('Perl::ToPerl6::Transformation', 'set_format');
    can_ok('Perl::ToPerl6::Transformation', 'to_string');
} # end scope block

#-----------------------------------------------------------------------------
# Constructor Failures:
{
    eval { Perl::ToPerl6::Transformation->new('desc', 'expl'); };
    ok($EVAL_ERROR, 'new, wrong number of args');
    eval { Perl::ToPerl6::Transformation->new('desc', 'expl', {}, 'severity'); };
    ok($EVAL_ERROR, 'new, bad arg');
} # end scope block

#-----------------------------------------------------------------------------
# Accessor tests

{
    my $pkg  = __PACKAGE__;
    my $code = 'Hello World;';
    my $document = PPI::Document->new(\$code);
    my $no_diagnostics_msg = qr/ \s* No [ ] diagnostics [ ] available \s* /xms;
    my $viol = Perl::ToPerl6::Transformation->new( 'Foo', 'Bar', $document, 99, );

    is(   $viol->description(),          'Foo',           'description');
    is(   $viol->explanation(),          'Bar',           'explanation');
    is(   $viol->line_number(),          1,               'line_number');
    is(   $viol->logical_line_number(),  1,               'logical_line_number');
    is(   $viol->column_number(),        1,               'column_number');
    is(   $viol->visual_column_number(), 1,               'visual_column_number');
    is(   $viol->severity(),             99,              'severity');
    is(   $viol->source(),               $code,           'source');
    is(   $viol->transformer(),               $pkg,            'transformer');
    is(   $viol->element_class(),        'PPI::Document', 'element class');
    like( $viol->diagnostics(), qr/ \A $no_diagnostics_msg \z /xms, 'diagnostics');

    {
        my $old_format = Perl::ToPerl6::Transformation::get_format();
        Perl::ToPerl6::Transformation::set_format('%l,%c,%m,%e,%p,%d,%r');
        my $expect = qr/\A 1,1,Foo,Bar,$pkg,$no_diagnostics_msg,\Q$code\E \z/xms;

        like($viol->to_string(), $expect, 'to_string');
        like("$viol",            $expect, 'stringify');

        Perl::ToPerl6::Transformation::set_format($old_format);
    }

    $viol = Perl::ToPerl6::Transformation->new('Foo', [28], $document, 99);
    is($viol->explanation(), 'See page 28 of PBP', 'explanation');

    $viol = Perl::ToPerl6::Transformation->new('Foo', [28,30], $document, 99);
    is($viol->explanation(), 'See pages 28,30 of PBP', 'explanation');
} # end scope block

{
    my $pkg  = __PACKAGE__;
    my $code = 'Say goodbye to the document;';
    my $document = PPI::Document->new(\$code);

    my $words = $document->find('PPI::Token::Word');
    my $word = $words->[0];

    my $no_diagnostics_msg = qr/ \s* No [ ] diagnostics [ ] available \s* /xms;
    my $viol = Perl::ToPerl6::Transformation->new( 'Foo', 'Bar', $word, 99, );

    # Make bye-bye with the document.  This will end up stripping the guts out
    # of the PPI::Token::Word instance, so it is useless to us after the
    # document is gone.  We need to make sure that we've copied the data out
    # that we'll need.
    undef $document;
    undef $words;
    undef $word;

    is( $viol->description(),          'Foo',              'description after dropping document');
    is( $viol->explanation(),          'Bar',              'explanation after dropping document');
    is( $viol->line_number(),          1,                  'line_number after dropping document');
    is( $viol->logical_line_number(),  1,                  'logical_line_number after dropping document');
    is( $viol->column_number(),        1,                  'column_number after dropping document');
    is( $viol->visual_column_number(), 1,                  'visual_column_number after dropping document');
    is( $viol->severity(),             99,                 'severity after dropping document');
    is( $viol->source(),               $code,              'source after dropping document');
    is( $viol->transformer(),               $pkg,               'transformer after dropping document');
    is( $viol->element_class(),        'PPI::Token::Word', 'element class after dropping document');
    like(
        $viol->diagnostics(),
        qr/ \A $no_diagnostics_msg \z /xms,
        'diagnostics after dropping document',
    );
} # end scope block


#-----------------------------------------------------------------------------
# Import tests
{
    like(
        TransformationTest->get_transformation()->diagnostics(),
        qr/ \A \s* This [ ] is [ ] a [ ] test [ ] diagnostic [.] \s*\z /xms,
        'import diagnostics',
    );
} # end scope block

#-----------------------------------------------------------------------------
# Transformation sorting

SKIP: {
    my $code = <<'END_PERL';
my $foo = 1; my $bar = 2;
my $baz = 3;
END_PERL

    my $document = PPI::Document->new(\$code);
    my @children   = $document->schildren();
    my @transformations =
        map { Perl::ToPerl6::Transformation->new($EMPTY, $EMPTY, $_, 0) }
            $document, @children;
    my @sorted = Perl::ToPerl6::Transformation->sort_by_location( reverse @transformations);
    is_deeply(\@sorted, \@transformations, 'sort_by_location');

    my @severities = (5, 3, 4, 0, 2, 1);
    @transformations =
        map { Perl::ToPerl6::Transformation->new($EMPTY, $EMPTY, $document, $_) }
        @severities;
    @sorted = Perl::ToPerl6::Transformation->sort_by_severity( @transformations );
    is_deeply( [map {$_->severity()} @sorted], [sort @severities], 'sort_by_severity');
}

#-----------------------------------------------------------------------------
# Transformation formatting

{
    my $format = '%l; %c; %m; %e; %s; %r; %P; %p; %d';
    my $expected = join q{; }, (
       1, 1,  # line, col
       'desc', 'expl',
       1, # severity
       'print;', # source near token[0]
       'Perl::ToPerl6::Transformer::Test', 'Test', # long, short
       '    diagnostic',
    );

    Perl::ToPerl6::Transformation::set_format($format);
    is(Perl::ToPerl6::Transformation::get_format(), $format, 'set/get_format');
    my $code = "print;\n";
    my $document = PPI::Document->new(\$code);
    $document->index_locations();
#    my $p = Perl::ToPerl6::Transformer::Test->new();
    my @t = $document->tokens();
#    my $v = $p->transform($t[0]);
#    ok($v, 'got a transformation');

#    is($v->to_string(), $expected, 'to_string()');
}

#-----------------------------------------------------------------------------
# More formatting

{
    # Alias subroutines, because I'm lazy
    my $get_format = *Perl::ToPerl6::Transformation::get_format;
    my $set_format = *Perl::ToPerl6::Transformation::set_format;

    my $fmt_literal = 'Found %m in file %f on line %l\n';  ## no mogrify (RequireInterpolationOfMetachars)
    my $fmt_interp  = "Found %m in file %f on line %l\n"; #Same, but double-quotes
    is($set_format->($fmt_literal), $fmt_interp, 'set_format by spec');
    is($get_format->(), $fmt_interp, 'get_format by spec');

    my $fmt_predefined = "%m at %f line %l\n";
    is($set_format->(3), $fmt_predefined, 'set_format by number');
    is($get_format->(),  $fmt_predefined, 'get_format by number');

    my $fmt_default = "%m at line %l, column %c.  %e.  (Severity: %s)\n";
    is($set_format->(999),   $fmt_default, 'set_format by invalid number');
    is($get_format->(),      $fmt_default, 'get_format by invalid number');
    is($set_format->(undef), $fmt_default, 'set_format with undef');
    is($get_format->(),      $fmt_default, 'get_format with undef');

}

#-----------------------------------------------------------------------------

{
    my @given = ( qw(foo bar. .baz.. nuts!), [], {} );
    my @want  = ( qw(foo bar  .baz   nuts!), [], {} );
    my @have  = Perl::ToPerl6::Transformation::_chomp_periods(@given);

    is_deeply(\@have, \@want, 'Chomping periods');
} # end scope block

#-----------------------------------------------------------------------------

{
    my $filename = catfile( qw< t 06_transformation.d source Line.pm > );
    my $document = PPI::Document::File->new($filename);

    my @words = @{ $document->find('PPI::Token::Word') };

    is(
        (scalar @words),
        2,
        'Got the expected number of words in the line directive example document.',
    );


    my %expected = (
        '%F' => basename($filename),
        '%f' => $filename,
        '%G' => basename($filename),
        '%g' => $filename,
        '%l' => '1',
        '%L' => '1',
    );

    _test_file_and_line_formats($words[0], \%expected);


    @expected{ qw< %F %f > } = ('Thingy.pm') x 2;
    $expected{'%l'} = 57;
    $expected{'%L'} = 3;

    _test_file_and_line_formats($words[1], \%expected);
}

sub _test_file_and_line_formats {
    my ($word, $expected) = @_;

    my $transformation = Perl::ToPerl6::Transformation->new($EMPTY, $EMPTY, $word, 0);

    foreach my $format ( sort keys %{$expected} ) {
        Perl::ToPerl6::Transformation::set_format($format);
        is(
            $transformation->to_string(),
            $expected->{$format},
            "Got expected value for $format for " . $word->content(),
        );
    }

    return;
}

#-----------------------------------------------------------------------------
# ensure we return true if this test is loaded by
# t/06_transformation.t_without_optional_dependencies.t

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
