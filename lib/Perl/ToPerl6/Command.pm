package Perl::ToPerl6::Command;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use Getopt::Long qw< GetOptions >;
use List::Util qw< first max >;
use Pod::Usage qw< pod2usage >;

use Perl::ToPerl6::Exception::Parse ();
use Perl::ToPerl6::Utils qw<
    :characters :severities transformer_short_name
    $DEFAULT_VERBOSITY $DEFAULT_VERBOSITY_WITH_FILE_NAME
>;
use Perl::ToPerl6::Utils::Constants qw< $_MODULE_VERSION_TERM_ANSICOLOR >;
use Perl::ToPerl6::Transformation qw<>;

#-----------------------------------------------------------------------------

our $VERSION = '0.040';

#-----------------------------------------------------------------------------

use Exporter 'import';

Readonly::Array our @EXPORT_OK => qw< run >;

Readonly::Hash our %EXPORT_TAGS => ( all => [ @EXPORT_OK ] );

#-----------------------------------------------------------------------------

Readonly::Scalar my $DEFAULT_VIOLATIONS_FOR_TOP => 20;

Readonly::Scalar my $EXIT_SUCCESS           => 0;
Readonly::Scalar my $EXIT_NO_FILES          => 1;
Readonly::Scalar my $EXIT_HAD_FILE_PROBLEMS => 2;

#-----------------------------------------------------------------------------

my @files = ();
my $mogrify = undef;
my $output = \*STDOUT;

#-----------------------------------------------------------------------------

sub _out {
    my @lines = @_;
    return print {$output} @lines;
}

#-----------------------------------------------------------------------------

sub run {
    my %options = _get_options();
    @files      = _get_input(@ARGV);

    my ($transformations, $had_error_in_file) = _transform(\%options, @files);

    return $EXIT_HAD_FILE_PROBLEMS  if $had_error_in_file;
    return $EXIT_NO_FILES           if not defined $transformations;

    return $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _get_options {

    my %opts = _parse_command_line();
    _dispatch_special_requests( %opts );
    _validate_options( %opts );

    # Convert necessity shortcut options.  If multiple shortcuts
    # are given, the lowest one wins.  If an explicit --necessity
    # option has been given, then the shortcuts are ignored. The
    # @NECESSITY_NAMES variable is exported by Perl::ToPerl6::Utils.
    $opts{-necessity} ||= first { exists $opts{"-$_"} } @NECESSITY_NAMES;
    $opts{-necessity} ||= first { exists $opts{"-$_"} } ($NECESSITY_LOWEST ..  $NECESSITY_HIGHEST);


    # If --top is specified, default the necessity level to 1, unless an
    # explicit necessity is defined.  This provides us flexibility to
    # report top-offenders across just some or all of the necessity levels.
    # We also default the --top count to twenty if none is given
    if ( exists $opts{-top} ) {
        $opts{-necessity} ||= 1;
        $opts{-top} ||= $DEFAULT_VIOLATIONS_FOR_TOP;
    }

    #Override profile, if --noprofile is specified
    if ( exists $opts{-noprofile} ) {
        $opts{-profile} = $EMPTY;
    }

    return %opts;
}

#-----------------------------------------------------------------------------

sub _parse_command_line {
    my %opts;
    my @opt_specs = _get_option_specification();
    Getopt::Long::Configure('no_ignore_case');
    GetOptions( \%opts, @opt_specs ) || pod2usage();           #Exits

    # I've adopted the convention of using key-value pairs for
    # arguments to most functions.  And to increase legibility,
    # I have also adopted the familiar command-line practice
    # of denoting argument names with a leading dash (-).
    my %dashed_opts = map { ( "-$_" => $opts{$_} ) } keys %opts;
    return %dashed_opts;
}

#-----------------------------------------------------------------------------

sub _dispatch_special_requests {
    my (%opts) = @_;
    if ( $opts{-help}            ) { pod2usage( -verbose => 0 )    }  # Exits
    if ( $opts{-options}         ) { pod2usage( -verbose => 1 )    }  # Exits
    if ( $opts{-man}             ) { pod2usage( -verbose => 2 )    }  # Exits
    if ( $opts{-version}         ) { _display_version()            }  # Exits
    if ( $opts{-list}            ) { _render_all_transformer_listing()  }  # Exits
    if ( $opts{'-list-enabled'}  ) { _render_transformer_listing(%opts) }  # Exits
    if ( $opts{'-list-themes'}   ) { _render_theme_listing()       }  # Exits
    if ( $opts{'-profile-proto'} ) { _render_profile_prototype()   }  # Exits
    if ( $opts{-doc}             ) { _render_transformer_docs( %opts )  }  # Exits
    return 1;
}

#-----------------------------------------------------------------------------

sub _validate_options {
    my (%opts) = @_;
    my $msg = $EMPTY;


    if ( $opts{-noprofile} && $opts{-profile} ) {
        $msg .= qq{Warning: Cannot use -noprofile with -profile option.\n};
    }

    if ( $opts{-verbose} && $opts{-verbose} !~ m{(?: \d+ | %[mfFlcCedrpPs] )}xms) {
        $msg .= qq<Warning: --verbose arg "$opts{-verbose}" looks odd.  >;
        $msg .= qq<Perhaps you meant to say "--verbose 3 $opts{-verbose}."\n>;
    }

    if ( exists $opts{-top} && $opts{-top} < 0 ) {
        $msg .= qq<Warning: --top argument "$opts{-top}" is negative.  >;
        $msg .= qq<Perhaps you meant to say "$opts{-top} --top".\n>;
    }

    if (
            exists $opts{-necessity}
        &&  (
                    $opts{-necessity} < $NECESSITY_LOWEST
                ||  $opts{-necessity} > $NECESSITY_HIGHEST
            )
    ) {
        $msg .= qq<Warning: --necessity arg "$opts{-necessity}" out of range.  >;
        $msg .= qq<Severities range from "$NECESSITY_LOWEST" (lowest) to >;
        $msg .= qq<"$NECESSITY_HIGHEST" (highest).\n>;
    }


    if ( $msg ) {
        pod2usage( -exitstatus => 1, -message => $msg, -verbose => 0); #Exits
    }


    return 1;
}

#-----------------------------------------------------------------------------

sub _get_input {

    my @args = @_;

    if ( !@args || (@args == 1 && $args[0] eq q{-}) )  {

        # Reading code from STDIN.  All the code is slurped into
        # a string.  PPI will barf if the string is just whitespace.
        my $code_string = do { local $RS = undef; <STDIN> };

        # Notice if STDIN was closed (pipe error, etc)
        if ( ! defined $code_string ) {
            $code_string = $EMPTY;
        }

        $code_string =~ m{ \S+ }xms || die qq{Nothing to transform.\n};
        return \$code_string;    #Convert to SCALAR ref for PPI
    }
    else {

        # Test to make sure all the specified files or directories
        # actually exist.  If any one of them is bogus, then die.
        if ( my $nonexistent = first { ! -e } @args ) {
            my $msg = qq{No such file or directory: '$nonexistent'};
            pod2usage( -exitstatus => 1, -message => $msg, -verbose => 0);
        }

        # Reading code from files or dirs.  If argument is a file,
        # then we process it as-is (even though it may not actually
        # be Perl code).  If argument is a directory, recursively
        # search the directory for files that look like Perl code.
        return map { (-d) ? Perl::ToPerl6::Utils::all_perl_files($_) : $_ } @args;
    }
}

#------------------------------------------------------------------------------

sub _transform {

    my ( $opts_ref, @files_to_transform ) = @_;
    @files_to_transform || die "No perl files were found.\n";

    # Perl::ToPerl6 has lots of dependencies, so loading is delayed
    # until it is really needed.  This hack reduces startup time for
    # doing other things like getting the version number or dumping
    # the man page. Arguably, those things are pretty rare, but hey,
    # why not save a few seconds if you can.

    require Perl::ToPerl6;
    $mogrify = Perl::ToPerl6->new( %{$opts_ref} );
    $mogrify->transformers() || die "No transformers selected.\n";

    _set_up_pager($mogrify->config()->pager());

    my $number_of_transformations = undef;
    my $had_error_in_file = 0;

    for my $file (@files_to_transform) {

        eval {
            my @transformations = $mogrify->transform($file);
            $number_of_transformations += scalar @transformations;

            if (not $opts_ref->{'-statistics-only'}) {
                _render_report( $file, $opts_ref, @transformations )
            }
            1;
        }
        or do {
            if ( my $exception = Perl::ToPerl6::Exception::Parse->caught() ) {
                $had_error_in_file = 1;
                warn qq<Problem while mogrifying "$file": $EVAL_ERROR\n>;
            }
            elsif ($EVAL_ERROR) {
                # P::C::Exception::Fatal includes the stack trace in its
                # stringification.
                die qq<Fatal error while mogrifying "$file": $EVAL_ERROR\n>;
            }
            else {
                die qq<Fatal error while mogrifying "$file". Unfortunately, >,
                    q<$@/$EVAL_ERROR >,
                    qq<is empty, so the reason can't be shown.\n>;
            }
        }
    }

    if ( $opts_ref->{-statistics} or $opts_ref->{'-statistics-only'} ) {
        my $stats = $mogrify->statistics();
        _report_statistics( $opts_ref, $stats );
    }

    return $number_of_transformations, $had_error_in_file;
}

#------------------------------------------------------------------------------

sub _render_report {
    my ( $file, $opts_ref, @transformations ) = @_;

    # Only report the files, if asked.
    my $number_of_transformations = scalar @transformations;
    if ( $opts_ref->{'-files-with-transformations'} ||
        $opts_ref->{'-files-without-transformations'} ) {
        not ref $file
            and $opts_ref->{$number_of_transformations ? '-files-with-transformations' :
            '-files-without-transformations'}
            and _out "$file\n";
        return $number_of_transformations;
    }

    # Only report the number of transformations, if asked.
    if( $opts_ref->{-count} ){
        ref $file || _out "$file: ";
        _out "$number_of_transformations\n";
        return $number_of_transformations;
    }

    # Hail all-clear unless we should shut up.
    if( !@transformations && !$opts_ref->{-quiet} ) {
        ref $file || _out "$file ";
        _out "source OK\n";
        return 0;
    }

    # Otherwise, format and print transformations
    my $verbosity = $mogrify->config->verbose();
    # $verbosity can be numeric or string, so use "eq" for comparison;
    $verbosity =
        ($verbosity eq $DEFAULT_VERBOSITY && @files > 1)
            ? $DEFAULT_VERBOSITY_WITH_FILE_NAME
            : $verbosity;
    my $fmt = Perl::ToPerl6::Utils::verbosity_to_format( $verbosity );
    if (not -f $file) { $fmt =~ s< \%[fF] ><STDIN>xms; } #HACK!
    Perl::ToPerl6::Transformation::set_format( $fmt );

    my $color = $mogrify->config->color();
    if ( $mogrify->config->detail() ) {
        @transformations = grep {
            $_->necessity <= $mogrify->config->detail()
        } @transformations;
    }
    _out $color ? _colorize_by_necessity(@transformations) : @transformations;

    return $number_of_transformations;
}

#-----------------------------------------------------------------------------

sub _set_up_pager {
    my ($pager_command) = @_;
    return if not $pager_command;
    return if not _at_tty();

    open my $pager, q<|->, $pager_command
        or die qq<Unable to pipe to pager "$pager_command": $ERRNO\n>;

    $output = $pager;

    return;
}

#-----------------------------------------------------------------------------

sub _report_statistics {
    my ($opts_ref, $statistics) = @_;

    if (
            not $opts_ref->{'-statistics-only'}
        and (
                $statistics->total_transformations()
            or  not $opts_ref->{-quiet} and $statistics->modules()
        )
    ) {
        _out "\n"; # There's prior output that we want to separate from.
    }

    my $files = _commaify($statistics->modules());
    my $subroutines = _commaify($statistics->subs());
    my $statements = _commaify($statistics->statements_other_than_subs());
    my $lines = _commaify($statistics->lines());
    my $width = max map { length } $files, $subroutines, $statements;

    _out sprintf "%*s %s.\n", $width, $files, 'files';
    _out sprintf "%*s %s.\n", $width, $subroutines, 'subroutines/methods';
    _out sprintf "%*s %s.\n", $width, $statements, 'statements';

    _out _commaify($statistics->total_transformations()), " transformations.\n";

    my $transformations_per_file = $statistics->transformations_per_file();
    if (defined $transformations_per_file) {
        _out
            sprintf
                "Transformations per file was %.3f.\n",
                $transformations_per_file;
    }
    my $transformations_per_statement = $statistics->transformations_per_statement();
    if (defined $transformations_per_statement) {
        _out
            sprintf
                "Transformations per statement was %.3f.\n",
                $transformations_per_statement;
    }
    my $transformations_per_line = $statistics->transformations_per_line_of_code();
    if (defined $transformations_per_line) {
        _out
            sprintf
                "Transformations per line of code was %.3f.\n",
                $transformations_per_line;
    }

    if ( $statistics->total_transformations() ) {
        _out "\n";

        my %necessity_transformations = %{ $statistics->transformations_by_necessity() };
        my @severities = reverse sort keys %necessity_transformations;
        $width =
            max
                map { length _commaify( $necessity_transformations{$_} ) }
                    @severities;
        foreach my $necessity (@severities) {
            _out
                sprintf
                    "%*s necessity %d transformations.\n",
                    $width,
                    _commaify( $necessity_transformations{$necessity} ),
                    $necessity;
        }

        _out "\n";

        my %transformer_transformations = %{ $statistics->transformations_by_transformer() };
        my @transformers = sort keys %transformer_transformations;
        $width =
            max
                map { length _commaify( $transformer_transformations{$_} ) }
                    @transformers;
        foreach my $transformer (@transformers) {
            _out
                sprintf
                    "%*s transformations of %s.\n",
                    $width,
                    _commaify($transformer_transformations{$transformer}),
                    transformer_short_name($transformer);
        }
    }

    return;
}

#-----------------------------------------------------------------------------

# Only works for integers.
sub _commaify {
    my ( $number ) = @_;

    while ($number =~ s/ \A ( [-+]? \d+ ) ( \d{3} ) /$1,$2/xms) {
        # nothing
    }

    return $number;
}

#-----------------------------------------------------------------------------

sub _get_option_specification {

    return qw<
        5 4 3 2 1
        Safari
        version
        brutal
        count|C
        cruel
        doc=s
        exclude=s@
        force!
        gentle
        harsh
        help|?|H
        include=s@
        list
        list-enabled
        list-themes
        man
        color|colour!
        noprofile
        in-place!
        only!
        options
        pager=s
        profile|p=s
        profile-proto
        quiet
        necessity=i
        detail=i
        single-transformer|s=s
        stern
        statistics!
        statistics-only!
        profile-strictness=s
        theme=s
        top:i
        verbose=s
        color-necessity-highest|colour-necessity-highest|color-necessity-5|colour-necessity-5=s
        color-necessity-high|colour-necessity-high|color-necessity-4|colour-necessity-4=s
        color-necessity-medium|colour-necessity-medium|color-necessity-3|colour-necessity-3=s
        color-necessity-low|colour-necessity-low|color-necessity-2|colour-necessity-2=s
        color-necessity-lowest|colour-necessity-lowest|color-necessity-1|colour-necessity-1=s
        files-with-transformations|l
        files-without-transformations|L
        program-extensions=s@
    >;
}

#-----------------------------------------------------------------------------

sub _colorize_by_necessity {
    my @transformations = @_;
    return @transformations if _this_is_windows();
    return @transformations if not eval {
        require Term::ANSIColor;
        Term::ANSIColor->VERSION( $_MODULE_VERSION_TERM_ANSICOLOR );
        1;
    };

    my $config = $mogrify->config();
    my %color_of = (
        $NECESSITY_HIGHEST   => $config->color_necessity_highest(),
        $NECESSITY_HIGH      => $config->color_necessity_high(),
        $NECESSITY_MEDIUM    => $config->color_necessity_medium(),
        $NECESSITY_LOW       => $config->color_necessity_low(),
        $NECESSITY_LOWEST    => $config->color_necessity_lowest(),
    );

    return map { _colorize( "$_", $color_of{$_->necessity()} ) } @transformations;

}

#-----------------------------------------------------------------------------

sub _colorize {
    my ($string, $color) = @_;
    return $string if not defined $color;
    return $string if $color eq $EMPTY;
    # $terminator is a purely cosmetic change to make the color end at the end
    # of the line rather than right before the next line. It is here because
    # if you use background colors, some console windows display a little
    # fragment of colored background before the next uncolored (or
    # differently-colored) line.
    my $terminator = chomp $string ? "\n" : $EMPTY;
    return  Term::ANSIColor::colored( $string, $color ) . $terminator;
}

#-----------------------------------------------------------------------------

sub _this_is_windows {
    return 1 if $OSNAME =~ m/MSWin32/xms;
    return 0;
}

#-----------------------------------------------------------------------------

sub _at_tty {
    return -t STDOUT;
}

#-----------------------------------------------------------------------------

sub _render_all_transformer_listing {
    # Force P-C parameters, to catch all Transformers on this site
    my %pc_params = (-profile => $EMPTY, -necessity => $NECESSITY_LOWEST);
    return _render_transformer_listing( %pc_params );
}

#-----------------------------------------------------------------------------

sub _render_transformer_listing {
    my %pc_params = @_;

    require Perl::ToPerl6::TransformerListing;
    require Perl::ToPerl6;

    my @transformers = Perl::ToPerl6->new( %pc_params )->transformers();
    my $listing = Perl::ToPerl6::TransformerListing->new( -transformers => \@transformers );
    _out $listing;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _render_theme_listing {

    require Perl::ToPerl6::ThemeListing;
    require Perl::ToPerl6;

    my %pc_params = (-profile => $EMPTY, -necessity => $NECESSITY_LOWEST);
    my @transformers = Perl::ToPerl6->new( %pc_params )->transformers();
    my $listing = Perl::ToPerl6::ThemeListing->new( -transformers => \@transformers );
    _out $listing;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _render_profile_prototype {

    require Perl::ToPerl6::ProfilePrototype;
    require Perl::ToPerl6;

    my %pc_params = (-profile => $EMPTY, -necessity => $NECESSITY_LOWEST);
    my @transformers = Perl::ToPerl6->new( %pc_params )->transformers();
    my $prototype = Perl::ToPerl6::ProfilePrototype->new( -transformers => \@transformers );
    _out $prototype;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _render_transformer_docs {

    my (%opts) = @_;
    my $pattern = delete $opts{-doc};

    require Perl::ToPerl6;
    $mogrify = Perl::ToPerl6->new(%opts);
    _set_up_pager($mogrify->config()->pager());

    require Perl::ToPerl6::TransformerFactory;
    my @site_transformers  = Perl::ToPerl6::TransformerFactory->site_transformer_names();
    my @matching_transformers  = grep { /$pattern/ixms } @site_transformers;

    # "-T" means don't send to pager
    my @perldoc_output = map {`perldoc -T $_`} @matching_transformers;
    _out @perldoc_output;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _display_version {
    _out "$VERSION\n";
    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------
1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords
Twitter

=head1 NAME

Perl::ToPerl6::Command - Guts of L<perlmogrify|perlmogrify>.


=head1 SYNOPSIS

    use Perl::ToPerl6::Command qw< run >;

    local @ARGV = qw< --statistics-only lib bin >;
    run();


=head1 DESCRIPTION

This is the implementation of the L<perlmogrify|perlmogrify> command.  You can use
this to run the command without going through a command interpreter.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  However, its interface is
experimental, and will likely change.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<run()>

Does the equivalent of the L<perlmogrify|perlmogrify> command.  Unfortunately, at
present, this doesn't take any parameters but uses C<@ARGV> to get its
input instead.  Count on this changing; don't count on the current
interface.


=back


=head1 TO DO

Make C<run()> take parameters.  The equivalent of C<@ARGV> should be
passed as a reference.

Turn this into an object.


=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>


=head1 AUTHOR EMERITUS

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
