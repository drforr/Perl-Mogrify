package Perl::ToPerl6::TestUtils;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Exporter 'import';

use File::Path ();
use File::Spec ();
use File::Spec::Unix ();
use File::Temp ();
use File::Find qw( find );

use Perl::ToPerl6;
use Perl::ToPerl6::Config;
use Perl::ToPerl6::Exception::Fatal::Generic qw{ &throw_generic };
use Perl::ToPerl6::Exception::Fatal::Internal qw{ &throw_internal };
use Perl::ToPerl6::Utils qw{ :severities :data_conversion transformer_long_name };
use Perl::ToPerl6::TransformerFactory (-test => 1);

Readonly::Array our @EXPORT_OK => qw(
    ptransform ptransform_with_transformations
    transform  transform_with_transformations
    ftransform ftransform_with_transformations
    subtests_in_tree
    should_skip_author_tests
    get_author_test_skip_message
    starting_points_including_examples
    bundled_transformer_names
    names_of_transformers_willing_to_work
);

#-----------------------------------------------------------------------------
# If the user already has an existing perlmogrifyrc file, it will get
# in the way of these test.  This little tweak to ensures that we
# don't find the perlmogrifyrc file.

sub block_perlmogrifyrc {
    no warnings 'redefine';
    *Perl::ToPerl6::UserProfile::_find_profile_path = sub { return };
    return 1;
}

#-----------------------------------------------------------------------------
# ToPerl6 a code snippet using only one transformer.  Returns the transformations.
#
# Also uses a secret escape hatch in $c->transform() so we can get at the
# raw PPI::Document object without breaking AUTOLOAD.

sub ptransform_with_transformations {
    my($transformer, $code_ref, $config_ref) = @_;
    my $c = Perl::ToPerl6->new( -profile => 'NONE' );
    $c->apply_transform(-transformer => $transformer, -config => $config_ref);
    my $doc;
    $code_ref = \join("\n",@{$code_ref});
    my @rv = $c->transform($code_ref, doc => \$doc);
    return ($doc, @rv);
}

#-----------------------------------------------------------------------------
# Mogrifyize a code snippet using only one transformer.  Returns the number
# of transformations

sub ptransform {  ##no mogrify(ArgUnpacking)
    return scalar ptransform_with_transformations(@_);
}

#-----------------------------------------------------------------------------
# Mogrifyize a code snippet using a specified config.  Returns the transformations.

sub transform_with_transformations {
    my ($code_ref, $config_ref) = @_;
    my $c = Perl::ToPerl6->new( %{$config_ref} );
    return $c->transform($code_ref);
}

#-----------------------------------------------------------------------------
# Mogrifyize a code snippet using a specified config.  Returns the
# number of transformations

sub transform {  ##no mogrify(ArgUnpacking)
    return scalar transform_with_transformations(@_);
}

#-----------------------------------------------------------------------------
# Like ptransform_with_transformations, but forces a PPI::Document::File context.
# The $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

Readonly::Scalar my $TEMP_FILE_PERMISSIONS => oct 700;

sub ftransform_with_transformations {
    my($transformer, $code_ref, $filename, $config_ref) = @_;
    my $c = Perl::ToPerl6->new( -profile => 'NONE' );
    $c->apply_transform(-transformer => $transformer, -config => $config_ref);

    my $dir = File::Temp::tempdir( 'PerlMogrify-tmpXXXXXX', TMPDIR => 1 );
    $filename ||= 'Temp.pm';
    my @fileparts = File::Spec::Unix->splitdir($filename);
    if (@fileparts > 1) {
        my $subdir = File::Spec->catdir($dir, @fileparts[0..$#fileparts-1]);
        File::Path::mkpath($subdir, 0, $TEMP_FILE_PERMISSIONS);
    }
    my $file = File::Spec->catfile($dir, @fileparts);
    if (open my $fh, '>', $file) {
        print {$fh} ${$code_ref};
        close $fh or throw_generic "unable to close $file: $OS_ERROR";
    }

    # Use eval so we can clean up before throwing an exception in case of
    # error.
    my @v = eval {$c->transform($file)};
    my $err = $EVAL_ERROR;
    File::Path::rmtree($dir, 0, 1);
    if ($err) {
        throw_generic $err;
    }
    return @v;
}

#-----------------------------------------------------------------------------
# Like ptransform, but forces a PPI::Document::File context.  The
# $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

sub ftransform {  ##no mogrify(ArgUnpacking)
    return scalar ftransform_with_transformations(@_);
}

# Note: $include_extras is not documented in the POD because I'm not
# committing to the interface yet.
sub subtests_in_tree {
    my ($start, $include_extras) = @_;

    my %subtests;

    find(
        {
            wanted => sub {
                return if not -f;

                my ($fileroot) = m{(.+)[.]run\z}xms;

                return if not $fileroot;

                my @pathparts = File::Spec->splitdir($fileroot);
                if (@pathparts < 2) {
                    throw_internal 'confusing transformer test filename ' . $_;
                }

#                my $transformer = join q{::}, @pathparts[-2, -1];
		my @remaining_path = @pathparts;

		shift @remaining_path if $remaining_path[0] eq 't';
		shift @remaining_path if $remaining_path[0] eq 'Perl';
		shift @remaining_path if $remaining_path[0] eq 'ToPerl6';
		my $transformer = join q{::}, @remaining_path;

                my $globals = _globals_from_file( $_ );
                if ( my $prerequisites = $globals->{prerequisites} ) {
                    foreach my $prerequisite ( keys %{$prerequisites} ) {
                        eval "require $prerequisite; 1" or return;
                    }
                }

                my @subtests = _subtests_from_file( $_ );

                if ($include_extras) {
                    $subtests{$transformer} =
                        { subtests => [ @subtests ], globals => $globals };
                }
                else {
                    $subtests{$transformer} = [ @subtests ];
                }

                return;
            },
            no_chdir => 1,
        },
        $start
    );

    return \%subtests;
}

# Answer whether author test should be run.
#
# Note: this code is duplicated in
# t/tlib/Perl/ToPerl6/TestUtilitiesWithMinimalDependencies.pm.
# If you change this here, make sure to change it there.

sub should_skip_author_tests {
    return not $ENV{TEST_AUTHOR_PERL_MOGRIFY}
}

sub get_author_test_skip_message {
    return 'Author test.  Set $ENV{TEST_AUTHOR_PERL_MOGRIFY} to a true value to run.';
}


sub starting_points_including_examples {
    return (-e 'blib' ? 'blib' : 'lib', 'examples');
}

sub _globals_from_file {
    my $test_file = shift;

    my %valid_keys = hashify qw< prerequisites >;

    return if -z $test_file;  # Skip if the Transformer has a regular .t file.

    my %globals;

    open my $handle, '<', $test_file
        or throw_internal "Couldn't open $test_file: $OS_ERROR";

    while ( my $line = <$handle> ) {
        chomp;

        if (
            my ($key,$value) =
                $line =~ m<\A [#][#] [ ] global [ ] (\S+) (?:\s+(.+))? >xms
        ) {
            next if not $key;
            if ( not $valid_keys{$key} ) {
                throw_internal "Unknown global key $key in $test_file";
            }

            if ( $key eq 'prerequisites' ) {
                $value = { hashify( words_from_string($value) ) };
            }
            $globals{$key} = $value;
        }
    }
    close $handle or throw_generic "unable to close $test_file: $OS_ERROR";

    return \%globals;
}

# The internal representation of a subtest is just a hash with some
# named keys.  It could be an object with accessors for safety's sake,
# but at this point I don't see why.
sub _subtests_from_file {
    my $test_file = shift;

    my %valid_keys = hashify qw( name failures parms TODO error filename optional_modules );

    return if -z $test_file;  # Skip if the Transformer has a regular .t file.

    open my $fh, '<', $test_file
        or throw_internal "Couldn't open $test_file: $OS_ERROR";

    my @subtests;

    my $incode = 0;
    my $cut_in_code = 0;
    my $subtest;
    my $lineno;
    while ( <$fh> ) {
        ++$lineno;
        chomp;
        my $inheader = /^## name/ .. /^## cut/;

        my $line = $_;

        if ( $inheader ) {
            $line =~ m/\A [#]/xms or throw_internal "Code before cut: $test_file";
            my ($key,$value) = $line =~ m/\A [#][#] [ ] (\S+) (?:\s+(.+))? /xms;
            next if !$key;
            next if $key eq 'cut';
            if ( not $valid_keys{$key} ) {
                throw_internal "Unknown key $key in $test_file";
            }

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push @subtests, _finalize_subtest( $subtest );
                    undef $subtest;
                }
                $subtest->{lineno} = $lineno;
                $incode = 0;
                $cut_in_code = 0;
            }
            if ($incode) {
                throw_internal "Header line found while still in code: $test_file";
            }
            $subtest->{$key} = $value;
        }
        elsif ( $subtest ) {
            $incode = 1;
            $cut_in_code ||= $line =~ m/ \A [#][#] [ ] cut \z /smx;
            # Don't start a subtest if we're not in one.
            # Don't add to the test if we have seen a '## cut'.
            $cut_in_code or push @{$subtest->{code}}, $line;
        }
        elsif (@subtests) {
            ## don't complain if we have not yet hit the first test
            throw_internal "Got some code but I'm not in a subtest: $test_file";
        }
    }
    close $fh or throw_generic "unable to close $test_file: $OS_ERROR";
    if ( $subtest ) {
        if ( $incode ) {
            push @subtests, _finalize_subtest( $subtest );
        }
        else {
            throw_internal "Incomplete subtest in $test_file";
        }
    }

    return @subtests;
}

sub _split_subtest {
    my $code = shift;

    my (@original, @sample);
    my $original_done;
    for ( @{ $code } ) {
        if ( /^#-->/ ) {
            $original_done = 1;
            next;
        }
        elsif ( $original_done ) {
            push @sample, $_;
        }
        else {
            push @original, $_;
        }
    }
    return (\@original, \@sample);
}

sub _finalize_subtest {
    my $subtest = shift;

    if ( $subtest->{code} ) {
        my $code = delete $subtest->{code};
        @{$subtest}{qw(original sample)} = _split_subtest($code);
        delete $subtest->{code};
    }
    else {
        throw_internal "$subtest->{name} has no code lines";
    }
    if ( !defined $subtest->{failures} ) {
        throw_internal "$subtest->{name} does not specify failures";
    }
    if ($subtest->{parms}) {
        $subtest->{parms} = eval $subtest->{parms};
        if ($EVAL_ERROR) {
            throw_internal
                "$subtest->{name} has an error in the 'parms' property:\n"
                  . $EVAL_ERROR;
        }
        if ('HASH' ne ref $subtest->{parms}) {
            throw_internal
                "$subtest->{name} 'parms' did not evaluate to a hashref";
        }
    } else {
        $subtest->{parms} = {};
    }

    if (defined $subtest->{error}) {
        if ( $subtest->{error} =~ m{ \A / (.*) / \z }xms) {
            $subtest->{error} = eval {qr/$1/};
            if ($EVAL_ERROR) {
                throw_internal
                    "$subtest->{name} 'error' has a malformed regular expression";
            }
        }
    }

    return $subtest;
}

sub bundled_transformer_names {
    require ExtUtils::Manifest;
    my $manifest = ExtUtils::Manifest::maniread();
    my @transformer_paths = map {m{\A lib/(Perl/ToPerl6/Transformer/.*).pm \z}xms} keys %{$manifest};
    my @transformers = map { join q{::}, split m{/}xms } @transformer_paths;
    my @sorted_transformers = sort @transformers;
    return @sorted_transformers;
}

sub names_of_transformers_willing_to_work {
    my %configuration = @_;

    my @transformers_willing_to_work =
        Perl::ToPerl6::Config
            ->new( %configuration )
            ->transformers();

    return map { ref } @transformers_willing_to_work;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords RCS subtest subtests

=head1 NAME

Perl::ToPerl6::TestUtils - Utility functions for testing new Transformers.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 SYNOPSIS

    use Perl::ToPerl6::TestUtils qw(transform ptransform ftransform);

    my $code = '<<END_CODE';
    package Foo::Bar;
    $foo = frobulator();
    $baz = $foo ** 2;
    1;
    END_CODE

    # Critique code against all loaded transformers...
    my $perl_mogrify_config = { -necessity => 2 };
    my $transformation_count = transform( \$code, $perl_mogrify_config);

    # Critique code against one transformer...
    my $custom_transformer = 'Miscellanea::ProhibitFrobulation'
    my $transformation_count = ptransform( $custom_transformer, \$code );

    # Critique code against one filename-related transformer...
    my $custom_transformer = 'Modules::RequireFilenameMatchesPackage'
    my $transformation_count = ftransform( $custom_transformer, \$code, 'Foo/Bar.pm' );


=head1 DESCRIPTION

This module is used by L<Perl::ToPerl6|Perl::Critic> only for
self-testing. It provides a few handy subroutines for testing new
Perl::ToPerl6::Transformer modules.  Look at the test programs that ship with
Perl::ToPerl6 for more examples of how to use these subroutines.


=head1 EXPORTS

=over

=item block_perlmogrifyrc()

If a user has a F<~/.perlmogrifyrc> file, this can interfere with
testing.  This handy method disables the search for that file --
simply call it at the top of your F<.t> program.  Note that this is
not easily reversible, but that should not matter.


=item transform_with_transformations( $code_string_ref, $config_ref )

Test a block of code against the specified Perl::ToPerl6::Config
instance (or C<undef> for the default).  Returns the transformations that
occurred.


=item transform( $code_string_ref, $config_ref )

Test a block of code against the specified Perl::ToPerl6::Config
instance (or C<undef> for the default).  Returns the number of
transformations that occurred.


=item ptransform_with_transformations( $transformer_name, $code_string_ref, $config_ref )

Like C<transform_with_transformations()>, but tests only a single transformer
instead of the whole bunch.


=item ptransform( $transformer_name, $code_string_ref, $config_ref )

Like C<transform()>, but tests only a single transformer instead of the
whole bunch.


=item ftransform_with_transformations( $transformer_name, $code_string_ref, $filename, $config_ref )

Like C<ptransform_with_transformations()>, but pretends that the code was
loaded from the specified filename.  This is handy for testing
transformers like C<Modules::RequireFilenameMatchesPackage> which care
about the filename that the source derived from.

The C<$filename> parameter must be a relative path, not absolute.  The
file and all necessary subdirectories will be created via
L<File::Temp|File::Temp> and will be automatically deleted.


=item ftransform( $transformer_name, $code_string_ref, $filename, $config_ref )

Like C<ptransform()>, but pretends that the code was loaded from the
specified filename.  This is handy for testing transformers like
C<Modules::RequireFilenameMatchesPackage> which care about the
filename that the source derived from.

The C<$filename> parameter must be a relative path, not absolute.  The
file and all necessary subdirectories will be created via
L<File::Temp|File::Temp> and will be automatically deleted.


=item subtests_in_tree( $dir )

Searches the specified directory recursively for F<.run> files.  Each
one found is parsed and a hash-of-list-of-hashes is returned.  The
outer hash is keyed on transformer short name, like
C<Modules::RequireEndWithOne>.  The inner hash specifies a single test
to be handed to C<ptransform()> or C<ftransform()>, including the code
string, test name, etc.  See below for the syntax of the F<.run>
files.


=item should_skip_author_tests()

Answers whether author tests should run.


=item get_author_test_skip_message()

Returns a string containing the message that should be emitted when a
test is skipped due to it being an author test when author tests are
not enabled.


=item starting_points_including_examples()

Returns a list of the directories contain code that needs to be tested
when it is desired that the examples be included.


=item bundled_transformer_names()

Returns a list of Transformer packages that come bundled with this package.
This functions by searching F<MANIFEST> for
F<lib/Perl/ToPerl6/Transformer/*.pm> and converts the results to package
names.


=item names_of_transformers_willing_to_work( %configuration )

Returns a list of the packages of transformers that are willing to
function on the current system using the specified configuration.


=back


=head1 F<.run> file information

Testing a transformer follows a very simple pattern:

    * Transformer name
        * Subtest name
        * Optional parameters
        * Number of failures expected
        * Optional exception expected
        * Optional filename for code

Each of the subtests for a transformer is collected in a single F<.run>
file, with test properties as comments in front of each code block
that describes how we expect Perl::ToPerl6 to react to the code.  For
example, say you have a transformer called Variables::ProhibitVowels:

    (In file t/Variables/ProhibitVowels.run)

    ## name Basics
    ## failures 1
    ## cut

    my $vrbl_nm = 'foo';    # Good, vowel-free name
    my $wango = 12;         # Bad, pronouncable name


    ## name Sometimes Y
    ## failures 1
    ## cut

    my $yllw = 0;       # "y" not a vowel here
    my $rhythm = 12;    # But here it is

These are called "subtests", and two are shown above.  The beauty of
incorporating multiple subtests in a file is that the F<.run> is
itself a (mostly) valid Perl file, and not hidden in a HEREDOC, so
your editor's color-coding still works, and it is much easier to work
with the code and the POD.

If you need to pass any configuration parameters for your subtest, do
so like this:

    ## parms { allow_y => '0' }

Note that all the values in this hash must be strings because that's
what Perl::ToPerl6 will hand you from a F<.perlmogrifyrc>.

If it's a TODO subtest (probably because of some weird corner of PPI
that we exercised that Adam is getting around to fixing, right?), then
make a C<##TODO> entry.

    ## TODO Should pass when PPI 1.xxx comes out

If the code is expected to trigger an exception in the transformer,
indicate that like so:

    ## error 1

If you want to test the error message, mark it with C</.../> to
indicate a C<like()> test:

    ## error /Can't load Foo::Bar/

If the transformer you are testing cares about the filename of the code,
you can indicate that C<ftransform> should be used like so (see
C<ftransform> for more details):

    ## filename lib/Foo/Bar.pm

The value of C<parms> will get C<eval>ed and passed to C<ptransform()>,
so be careful.

In general, a subtest document runs from the C<## cut> that starts it to
either the next C<## name> or the end of the file. In very rare circumstances
you may need to end the test document earlier. A second C<## cut> will do
this. The only known need for this is in
F<t/Miscellanea/RequireRcsKeywords.run>, where it is used to prevent the RCS
keywords in the file footer from producing false positives or negatives in the
last test.

Note that nowhere within the F<.run> file itself do you specify the
transformer that you're testing.  That's implicit within the filename.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>
and the rest of the L<Perl::ToPerl6|Perl::Critic> team.


=head1 COPYRIGHT

Copyright (c) 2005-2011 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
