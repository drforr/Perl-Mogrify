#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use PPI::Document;

use Perl::ToPerl6::Annotation;
use Perl::ToPerl6::TestUtils qw(bundled_transformer_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.02';

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

my @bundled_transformer_names = bundled_transformer_names();

plan( tests => 85 );

#-----------------------------------------------------------------------------
# Test Perl::ToPerl6::Annotation module interface

can_ok('Perl::ToPerl6::Annotation', 'new');
can_ok('Perl::ToPerl6::Annotation', 'create_annotations');
can_ok('Perl::ToPerl6::Annotation', 'element');
can_ok('Perl::ToPerl6::Annotation', 'effective_range');
can_ok('Perl::ToPerl6::Annotation', 'disabled_transformers');
can_ok('Perl::ToPerl6::Annotation', 'disables_transformer');
can_ok('Perl::ToPerl6::Annotation', 'disables_all_transformers');
can_ok('Perl::ToPerl6::Annotation', 'disables_line');

annotate( <<"EOD", 0, 'Null case. Un-annotated document' );
#!/usr/local/bin/perl

print "Hello, world!\n";
EOD

annotate( <<"EOD", 1, 'Single block annotation for entire document' );

## no mogrify

print "Hello, world!\n";

EOD
my $note = choose_annotation( 0 );
ok( $note, 'Single block annotation defined' );
SKIP: {
    $note or skip( 'No annotation found', 4 );
    ok( $note->disables_all_transformers(),
        'Single block annotation disables all transformers' );
    ok( $note->disables_line( 4 ),
        'Single block annotation disables line 4' );
    my( $start, $finish ) = $note->effective_range();
    is( $start, 2,
        'Single block annotation starts at 2' );
    is( $finish, 6,
        'Single block annotation runs through 6' );
}

annotate( <<"EOD", 1, 'Block annotation for block (sorry!)' );

{
    ## no mogrify

    print "Hello, world!\n";
}

EOD
$note = choose_annotation( 0 );
ok( $note, 'Block annotation defined' );
SKIP: {
    $note or skip( 'No annotation found', 4 );
    ok( $note->disables_all_transformers(),
        'Block annotation disables all transformers' );
    ok( $note->disables_line( 5 ),
        'Block annotation disables line 5' );
    my( $start, $finish ) = $note->effective_range();
    is( $start, 3,
        'Block annotation starts at 3' );
    is( $finish, 6,
        'Block annotation runs through 6' );
}

SKIP: {
    foreach ( @bundled_transformer_names ) {
        m/ FroBozzBazzle /smxi or next;
        skip( 'Transformer FroBozzBazzle actually implemented', 6 );
        last;   # probably not necessary.
    }

    annotate( <<"EOD", 1, 'Bogus annotation' );

## no mogrify ( FroBozzBazzle )

print "Goodbye, cruel world!\n";

EOD

    $note = choose_annotation( 0 );
    ok( $note, 'Bogus annotation defined' );

    SKIP: {
        $note or skip( 'Bogus annotation not found', 4 );
        ok( ! $note->disables_all_transformers(),
            'Bogus annotation does not disable all transformers' );
        ok( $note->disables_line( 3 ),
            'Bogus annotation disables line 3' );
        my( $start, $finish ) = $note->effective_range();
        is( $start, 2,
            'Bogus annotation starts at 2' );
        is( $finish, 6,
            'Bogus annotation runs through 6' );
    }
}

SKIP: {
    @bundled_transformer_names >= 8
        or skip( 'Need at least 8 bundled transformers', 49 );
    my $max = 0;
    my $doc;
    my @annot;
    foreach my $fmt ( '(%s)', '( %s )', '"%s"', q<'%s'> ) {
        my $transformer_name = $bundled_transformer_names[$max++];
        $transformer_name =~ s/ .* :: //smx;
        $note = sprintf "no mogrify $fmt", $transformer_name;
        push @annot, $note;
        $doc .= "## $note\n## use mogrify\n";
        $transformer_name = $bundled_transformer_names[$max++];
        $transformer_name =~ s/ .* :: //smx;
        $note = sprintf "no mogrify qw$fmt", $transformer_name;
        push @annot, $note;
        $doc .= "## $note\n## use mogrify\n";
    }

    annotate( $doc, $max, 'Specific transformers in various formats' );
    foreach my $inx ( 0 .. $max - 1 ) {
        $note = choose_annotation( $inx );
        ok( $note, "Specific annotation $inx ($annot[$inx]) defined" );
        SKIP: {
            $note or skip( "No annotation $inx found", 5 );
            ok( ! $note->disables_all_transformers(),
                "Specific annotation $inx does not disable all transformers" );
            my ( $transformer_name ) = $bundled_transformer_names[$inx] =~
                m/ ( \w+ :: \w+ ) \z /smx;
            ok ( $note->disables_transformer( $bundled_transformer_names[$inx] ),
                "Specific annotation $inx disables $transformer_name" );
            my $line = $inx * 2 + 1;
            ok( $note->disables_line( $line ),
                "Specific annotation $inx disables line $line" );
            my( $start, $finish ) = $note->effective_range();
            is( $start, $line,
                "Specific annotation $inx starts at line $line" );
            is( $finish, $line + 1,
                "Specific annotation $inx runs through line " . ( $line + 1 ) );
        }
    }
}

annotate( <<"EOD", 1, 'Annotation on split statement' );

my \$foo =
    'bar'; ## no mogrify ($bundled_transformer_names[0])

my \$baz = 'burfle';
EOD
$note = choose_annotation( 0 );
ok( $note, 'Split statement annotation found' );
SKIP: {
    $note or skip( 'Split statement annotation not found', 4 );
    ok( ! $note->disables_all_transformers(),
        'Split statement annotation does not disable all transformers' );
    ok( $note->disables_line( 3 ),
        'Split statement annotation disables line 3' );
    my( $start, $finish ) = $note->effective_range();
    is( $start, 3,
        'Split statement annotation starts at line 3' );
    is( $finish, 3,
        'Split statement annotation runs through line 3' );
}

annotate (<<'EOD', 1, 'Ensure annotations can span __END__' );
## no mogrify (RequirePackageMatchesPodName)

package Foo;

__END__

=head1 NAME

Bar - The wrong name for this package

=cut
EOD
$note = choose_annotation( 0 );
ok( $note, 'Annotation (hopefully spanning __END__) found' );
SKIP: {
    skip( 'Annotation (hopefully spanning __END__) not found', 1 )
    if !$note;
    ok( $note->disables_line( 7 ),
        'Annotation disables the POD after __END__' );
}


#-----------------------------------------------------------------------------

{
    my $doc;            # P::C::Document, held to prevent annotations from
                        # going away due to garbage collection of the parent.
    my @annotations;    # P::C::Annotation objects

    sub annotate {  ## no mogrify (RequireArgUnpacking)
        my ( $source, $count, $title ) = @_;
        $doc = PPI::Document->new( \$source ) or do {
            @_ = ( "Can not make PPI::Document for $title" );
            goto &fail;
        };
        $doc = Perl::ToPerl6::Document->new( -source => $doc ) or do {
            @_ = ( "Can not make Perl::ToPerl6::Document for $title" );
            goto &fail;
        };
        @annotations = Perl::ToPerl6::Annotation->create_annotations( $doc );
        @_ = ( scalar @annotations, $count, $title );
        goto &is;
    }

    sub choose_annotation {
        my ( $index ) = @_;
        return $annotations[$index];
    }

}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/00_modules.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
