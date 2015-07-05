#!perl

use 5.006001;
use strict;
use warnings;

use Carp qw< carp >;

use version;


use Perl::Mogrify::Document qw< >;
use Perl::Mogrify::Utils qw< $EMPTY >;
use Perl::Mogrify::Utils::DataConversion qw< dor >;


use Test::Deep;
use Test::More tests => 43;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

can_ok('Perl::Mogrify::Document', 'new');
can_ok('Perl::Mogrify::Document', 'filename');
can_ok('Perl::Mogrify::Document', 'find');
can_ok('Perl::Mogrify::Document', 'find_first');
can_ok('Perl::Mogrify::Document', 'find_any');
can_ok('Perl::Mogrify::Document', 'namespaces');
can_ok('Perl::Mogrify::Document', 'subdocuments_for_namespace');
can_ok('Perl::Mogrify::Document', 'highest_explicit_perl_version');
can_ok('Perl::Mogrify::Document', 'uses_module');
can_ok('Perl::Mogrify::Document', 'ppi_document');
can_ok('Perl::Mogrify::Document', 'is_program');
can_ok('Perl::Mogrify::Document', 'is_module');

{
    my $code = q{'print 'Hello World';};  #Has 6 PPI::Element
    my $ppi_doc = PPI::Document->new( \$code );
    my $pc_doc  = Perl::Mogrify::Document->new( '-source' => $ppi_doc );
    isa_ok($pc_doc, 'Perl::Mogrify::Document');
    isa_ok($pc_doc, 'PPI::Document');
    isa_ok($pc_doc, 'PPI::Node');
    isa_ok($pc_doc, 'PPI::Element');


    my $nodes_ref = $pc_doc->find('PPI::Element');
    is( scalar @{ $nodes_ref }, 6, 'find by class name');

    $nodes_ref = $pc_doc->find( sub{ return 1 } );
    is( scalar @{ $nodes_ref }, 6, 'find by wanted() handler');

    $nodes_ref = $pc_doc->find( q{Element} );
    is( scalar @{ $nodes_ref }, 6, 'find by shortened class name');

    #---------------------------

    my $node = $pc_doc->find_first('PPI::Element');
    is( ref $node, 'PPI::Statement', 'find_first by class name');

    $node = $pc_doc->find_first( sub{ return 1 } );
    is( ref $node, 'PPI::Statement', 'find_first by wanted() handler');

    $node = $pc_doc->find_first( q{Element} );
    is( ref $node, 'PPI::Statement', 'find_first by shortened class name');

    #---------------------------

    my $found = $pc_doc->find_any('PPI::Element');
    is( $found, 1, 'find_any by class name');

    $found = $pc_doc->find_any( sub{ return 1 } );
    is( $found, 1, 'find_any by wanted() handler');

    $found = $pc_doc->find_any( q{Element} );
    is( $found, 1, 'find_any by shortened class name');

    #-------------------------------------------------------------------------

    {
        # Ignore "Cannot create search condition for 'PPI::': Not a PPI::Element"
        local $SIG{__WARN__} = sub {
            $_[0] =~ m/\QCannot create search condition for\E/xms || carp @_
        };
        $nodes_ref = $pc_doc->find( q{} );
        is( $nodes_ref, undef, 'find by empty class name');

        $node = $pc_doc->find_first( q{} );
        is( $node, undef, 'find_first by empty class name');

        $found = $pc_doc->find_any( q{} );
        is( $found, undef, 'find_any by empty class name');

    }

    #-------------------------------------------------------------------------

    cmp_deeply(
        [ $pc_doc->namespaces() ],
        ['main'],
        q<everything is in the "main" namespace>,
    );

    ok( $pc_doc->is_module(), q{document type 'module' is a module});
    ok( ! $pc_doc->is_program(), q{document type 'module' is not a program});

}

#-----------------------------------------------------------------------------

{
    my $ppi_document = PPI::Document->new(\'foo(); package Foo; package Bar');
    my $mogrify_document =
        Perl::Mogrify::Document->new(-source => $ppi_document);

    cmp_deeply(
        [ $mogrify_document->namespaces() ],
        bag( qw< main Foo Bar > ),
        'Got expected namespaces',
    );
}

#-----------------------------------------------------------------------------

{
    my $ppi_document = PPI::Document->new(\'use Moose');
    my $mogrify_document =
        Perl::Mogrify::Document->new(-source => $ppi_document);

    ok(!! $mogrify_document->uses_module('Moose'),       'Moose is used.');
    ok( ! $mogrify_document->uses_module('Moose::Role'), 'Moose::Role is not used.');

    $ppi_document = PPI::Document->new( \q{ } );
    $mogrify_document =
        Perl::Mogrify::Document->new(-source => $ppi_document);

    ok(
        ! $mogrify_document->uses_module('Blah'),
        q<uses_module() doesn't barf when there are no include statements.>,
    );
}

#-----------------------------------------------------------------------------


{
    test_version( 'sub { 1 }', undef );
    test_version( 'use 5.006', version->new('5.006') );
    test_version( 'use 5.8.3', version->new('5.8.3') );
    test_version(
        'use 5.006; use 5.8.3; use 5.005005',
        version->new('5.8.3'),
    );
    test_version( 'use 5.005_05; use 5.005_03', version->new('5.005_05') );
    test_version( 'use 5.005_03; use 5.005_05', version->new('5.005_05') );
}

sub test_version {
    my ($code, $expected_version) = @_;

    my $description_version = dor( $expected_version, '<undef>' );

    my $document =
        Perl::Mogrify::Document->new(
            '-source' => PPI::Document->new( \$code )
        );

    is(
        $document->highest_explicit_perl_version(),
        $expected_version,
        qq<Get "$description_version" for "$code".>,
    );

    return;
}

#-----------------------------------------------------------------------------

my $nameless_code = 'use strict';
my $nameless_doc = Perl::Mogrify::Document->new(
    '-source'               => \$nameless_code,
    '-filename-override'    => 'Build.PL'
);

is($nameless_doc->filename(), 'Build.PL', 'Got filename override.');
ok(
    ! $nameless_doc->is_module(),
    'Overridden file name affects module determination.'
);

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/08_document.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
