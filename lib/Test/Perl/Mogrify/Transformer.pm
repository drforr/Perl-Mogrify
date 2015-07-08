package Test::Perl::Mogrify::Transformer;

use 5.006001;

use strict;
use warnings;

use Carp qw< croak confess >;
use English qw< -no_match_vars >;
use List::Util qw< min >;
use List::MoreUtils qw< all none >;
use Readonly;

use Test::Builder qw<>;
use Test::More;

use Perl::Mogrify::Transformation;
use Perl::Mogrify::TestUtils qw<
    ptransform_with_transformations ftransform_with_transformations subtests_in_tree
>;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

use Exporter 'import';

Readonly::Array our @EXPORT_OK      => qw< all_transformers_ok >;
Readonly::Hash  our %EXPORT_TAGS    => (all => \@EXPORT_OK);

#-----------------------------------------------------------------------------

Perl::Mogrify::Transformation::set_format( "%m at line %l, column %c.  (%r)\n" );
Perl::Mogrify::TestUtils::block_perlmogrifyrc();

#-----------------------------------------------------------------------------

my $TEST = Test::Builder->new();

#-----------------------------------------------------------------------------

sub all_transformers_ok {
    my (%args) = @_;
    my $wanted_transformers = $args{-transformers};
    my $test_dir            = $args{'-test-directory'} || 't';

    my $subtests_with_extras =  subtests_in_tree( $test_dir, 'include extras' );

use Data::Dumper;die Dumper($subtests_with_extras);
#    if ($wanted_transformers) {
#        _validate_wanted_policy_names($wanted_transformers, $subtests_with_extras);
#        _filter_unwanted_subtests($wanted_transformers, $subtests_with_extras);
#    }
#
#    $TEST->plan( tests => _compute_test_count($subtests_with_extras) );
#    my $transformers_to_test = join q{, }, keys %{$subtests_with_extras};
#    $TEST->note("Running tests for transformers: $transformers_to_test");
#
#    for my $policy ( sort keys %{$subtests_with_extras} ) {
#
#	    my ($full_policy_name, $method) = ("Perl::Mogrify::Transformer::$policy", 'transform');
#	    my $can_ok_label = qq{Class '$full_policy_name' has method '$method'};
#	    $TEST->ok( $full_policy_name->can($method), $can_ok_label );
#
#	    for my $subtest ( @{ $subtests_with_extras->{$policy}{subtests} } ) {
#		    my $todo = $subtest->{TODO};
#		    if ($todo) { $TEST->todo_start( $todo ); }
#
#		    my ($error, @transformations) = _run_subtest($policy, $subtest);
#		    my ($ok, @diag)= _evaluate_test_results($subtest, $error, \@transformations);
#		    $TEST->ok( $ok, _create_test_name($policy, $subtest) );
#
#		    if (@diag) { $TEST->diag(@diag); }
#		    if ($todo) { $TEST->todo_end(); }
#	    }
#    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_wanted_policy_names {
    my ($wanted_transformers, $subtests_with_extras) = @_;
    return 1 if not $wanted_transformers;
    my @all_testable_transformers = keys %{ $subtests_with_extras };
    my @wanted_transformers = @{ $wanted_transformers };


    my @invalid = grep {my $p = $_; none { $_ =~ $p } @all_testable_transformers}  @wanted_transformers;
    croak( q{No tests found for transformers matching: } . join q{, }, @invalid ) if @invalid;
    return 1;
}

#-----------------------------------------------------------------------------

sub _filter_unwanted_subtests {
    my ($wanted_transformers, $subtests_with_extras) = @_;
    return 1 if not $wanted_transformers;
    my @all_testable_transformers = keys %{ $subtests_with_extras };
    my @wanted_transformers = @{ $wanted_transformers };

    for my $p (@all_testable_transformers) {
        if (none {$p =~ m/$_/xism} @wanted_transformers) {
            delete $subtests_with_extras->{$p}; # side-effects!
        }
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub __parse_results {
    my ($doc) = @_;
    my $results = { to => [], from => [] };
    my $in_to;
    for (split /\n/, $doc) {
        s{\s*##.+$}{};
        if ( /^#--/ ) {
            $in_to = 1;
            next;
        }
        if ( $in_to ) { push @{ $results->{to} }, $_ }
        else { push @{ $results->{from} }, $_ }
    }
    return $results;
}

#-----------------------------------------------------------------------------

sub __browse_deeply {
    my ($policy, $subtest, $results) = @_;

    my $num_errors;
    my $last_line = min( $#{ $results->{from} }, $#{ $results->{to} } );
    my $first_different_line = 0;
    for my $idx ( 0 .. $last_line ) {
        next if $results->{from}[$idx] eq $results->{to}[$idx];
        $first_different_line = $idx + 1;
        last;
    }
    if ( $first_different_line ) {
        $TEST->diag(
            "Output begins to differ at line $first_different_line:\n".
            join( "\n", @{ $results->{from} }, '====', @{ $results->{to} } )
        );
        $num_errors++;
    }
    elsif ( $#{ $results->{from} } > $#{ $results->{to} } ) {
        $TEST->diag(
            "Transformed file missing lines from original:\n".
            join( "\n", @{ $results->{from} }, '====', @{ $results->{to} } )
        );
        $num_errors++;
    }
    elsif ( $#{ $results->{from} } < $#{ $results->{to} } ) {
        $TEST->diag(
            "Transformed file has more lines than original:\n".
            join( "\n", @{ $results->{from} }, '====', @{ $results->{to} } )
        );
        $num_errors++;
    }
    return $num_errors;
}

#-----------------------------------------------------------------------------

sub _run_subtest {
    my ($policy, $subtest) = @_;

    my $document;
    my @transformations;
    my $error;
    if ( $subtest->{filename} ) {
        eval {
            @transformations =
                ftransform_with_transformations(
                    $policy,
                    \$subtest->{code},
                    $subtest->{filename},
                    $subtest->{parms},
                );
            1;
        } or do {
            $error = $EVAL_ERROR || 'An unknown problem occurred.';
        };
    }
    else {
        eval {
            ($document, @transformations) =
                ptransform_with_transformations(
                    $policy,
                    \$subtest->{code},
                    $subtest->{parms},
                );
            1;
        } or do {
            $error = $EVAL_ERROR || 'An unknown problem occurred.';
        };
    }
    my $results = __parse_results($document);
    my $num_errors = __browse_deeply($policy, $subtest, $results);

    if ( $num_errors ) {
        $TEST->ok(0==1, "$policy - $subtest->{name} - failed");
    }
    return;
}

#-----------------------------------------------------------------------------

sub _evaluate_test_results {
    my ($subtest, $error, $transformations) = @_;

    if ($subtest->{error}) {
        return _evaluate_error_case($subtest, $error);
    }
    elsif ($error) {
        confess $error;
    }
    else {
        return _evaluate_transformation_case($subtest, $transformations);
    }
}

#-----------------------------------------------------------------------------

sub _evaluate_transformation_case {
    my ($subtest, $transformations) = @_;
    my ($ok, @diagnostics);

    my @transformations = @{$transformations};
    my $have = scalar @transformations;
    my $want = _compute_wanted_transformation_count($subtest);
    if ( not $ok = $have == $want ) {
        my $msg = qq(Expected $want transformations, got $have. );
        if (@transformations) { $msg .= q(Found transformations follow...); }
        push @diagnostics, $msg . "\n";
        push @diagnostics, map { qq(Found transformation: $_) } @transformations;
    }

    return ($ok, @diagnostics)
}

#-----------------------------------------------------------------------------

sub _evaluate_error_case {
    my ($subtest, $error) = @_;
    my ($ok, @diagnostics);

    if ( 'Regexp' eq ref $subtest->{error} ) {
        $ok = $error =~ $subtest->{error}
          or push @diagnostics, qq(Error message '$error' doesn't match $subtest->{error}.);
    }
    else {
        $ok = $subtest->{error}
          or push @diagnostics, q(Didn't get an error message when we expected one.);
    }

    return ($ok, @diagnostics);
}

#-----------------------------------------------------------------------------

sub _compute_test_count {
    my ($subtests_with_extras) = @_;

    # one can_ok() for each policy
    my $ntransformers = scalar keys %{ $subtests_with_extras };

    my $nsubtests = 0;
    for my $subtest_with_extras ( values %{$subtests_with_extras} ) {
        # one [pf]transform() test per subtest
        $nsubtests += @{ $subtest_with_extras->{subtests} };
    }

    return $nsubtests + $ntransformers;
}

#-----------------------------------------------------------------------------

sub _compute_wanted_transformation_count {
    my ($subtest) = @_;

    # If any optional modules are NOT available, then there should be no transformations.
    return 0 if not _all_optional_modules_are_available($subtest);
    return $subtest->{failures};
}

#-----------------------------------------------------------------------------

sub _all_optional_modules_are_available {
    my ($subtest) = @_;
    my $optional_modules = $subtest->{optional_modules} or return 1;
    return all {eval "require $_;" or 0;} split m/,\s*/xms, $optional_modules;
}

#-----------------------------------------------------------------------------

sub _create_test_name {
    my ($policy, $subtest) = @_;
    return join ' - ', $policy, "line $subtest->{lineno}", $subtest->{name};
}

#-----------------------------------------------------------------------------
1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords subtest subtests RCS

=head1 NAME

Test::Perl::Mogrify::Transformer - A framework for testing your custom Policies

=head1 SYNOPSIS

    use Test::Perl::Mogrify::Transformer qw< all_transformers_ok >;

    # Assuming .run files are inside 't' directory...
    all_transformers_ok()

    # Or if your .run files are in a different directory...
    all_transformers_ok( '-test-directory' => 'run' );

    # And if you just want to run tests for some polices...
    all_transformers_ok( -transformers => ['Some::Transformer', 'Another::Transformer'] );

    # If you want your test program to accept short Transformer names as
    # command-line parameters...
    #
    # You can then test a single policy by running
    # "perl -Ilib t/policy-test.t My::Transformer".
    my %args = @ARGV ? ( -transformers => [ @ARGV ] ) : ();
    all_transformers_ok(%args);


=head1 DESCRIPTION

This module provides a framework for function-testing your custom
L<Perl::Mogrify::Transformer|Perl::Mogrify::Transformer> modules.  Transformer testing usually
involves feeding it a string of Perl code and checking its behavior.  In the
old days, those strings of Perl code were mixed directly in the test script.
That sucked.

B<NOTE:> This module is alpha code -- interfaces and implementation are
subject to major changes.  This module is an integral part of building and
testing L<Perl::Mogrify|Perl::Mogrify> itself, but you should not write any code
against this module until it has stabilized.


=head1 IMPORTABLE SUBROUTINES

=over

=item all_transformers_ok('-test-directory' => $path, -transformers => \@policy_names)

Loads all the F<*.run> files beneath the C<-test-directory> and runs the
tests.  If C<-test-directory> is not specified, it defaults to F<t/>.
C<-transformers> is an optional reference to an array of shortened Transformer names.
If C<-transformers> specified, only the tests for Policies that match one of the
C<m/$POLICY_NAME/imx> will be run.


=back


=head1 CREATING THE *.run FILES

Testing a policy follows a very simple pattern:

    * Transformer name
        * Subtest name
        * Optional parameters
        * Number of failures expected
        * Optional exception expected
        * Optional filename for code

Each of the subtests for a policy is collected in a single F<.run>
file, with test properties as comments in front of each code block
that describes how we expect Perl::Mogrify to react to the code.  For
example, say you have a policy called Variables::ProhibitVowels:

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
what Perl::Mogrify will hand you from a F<.perlmogrifyrc>.

If it's a TODO subtest (probably because of some weird corner of PPI
that we exercised that Adam is getting around to fixing, right?), then
make a C<##TODO> entry.

    ## TODO Should pass when PPI 1.xxx comes out

If the code is expected to trigger an exception in the policy,
indicate that like so:

    ## error 1

If you want to test the error message, mark it with C</.../> to
indicate a C<like()> test:

    ## error /Can't load Foo::Bar/

If the policy you are testing cares about the filename of the code,
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
policy that you're testing.  That's implicit within the filename.


=head1 BUGS AND CAVEATS AND TODO ITEMS

Add policy_ok() method for running subtests in just a single TODO file.

Can users mark this entire test as TODO or SKIP, using the normal mechanisms?

Allow us to specify the nature of the failures, and which one.  If there are
15 lines of code, and six of them fail, how do we know they're the right six?

Consolidate code from L<Perl::Mogrify::TestUtils|Perl::Mogrify::TestUtils> and possibly deprecate some
functions there.

Write unit tests for this module.

Test that we have a t/*/*.run for each lib/*/*.pm

=head1 AUTHOR

Andy Lester, Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009-2011 Andy Lester.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
