package Perl::ToPerl6;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Exporter 'import';

use File::Spec;
use List::MoreUtils qw< firstidx >;
use Scalar::Util qw< blessed >;

use Perl::ToPerl6::Exception::Configuration::Generic;
use Perl::ToPerl6::Config;
use Perl::ToPerl6::Transformation;
use Perl::ToPerl6::Document;
use Perl::ToPerl6::Statistics;
use Perl::ToPerl6::Utils qw< :characters hashify shebang_line >;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

Readonly::Array our @EXPORT_OK => qw(transform);

#=============================================================================
# PUBLIC methods

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_config} = $args{-config} || Perl::ToPerl6::Config->new( %args );
    $self->{_stats} = Perl::ToPerl6::Statistics->new();
    return $self;
}

#-----------------------------------------------------------------------------

sub config {
    my $self = shift;
    return $self->{_config};
}

#-----------------------------------------------------------------------------

sub apply_transform {
    my ( $self, @args ) = @_;
    #Delegate to Perl::ToPerl6::Config
    return $self->config()->apply_transform( @args );
}

#-----------------------------------------------------------------------------

sub transformers {
    my $self = shift;

    #Delegate to Perl::ToPerl6::Config
    return $self->config()->transformers();
}

#-----------------------------------------------------------------------------

sub statistics {
    my $self = shift;
    return $self->{_stats};
}

#-----------------------------------------------------------------------------

sub transform {

    #-------------------------------------------------------------------
    # This subroutine can be called as an object method or as a static
    # function.  In the latter case, the first argument can be a
    # hashref of configuration parameters that shall be used to create
    # an object behind the scenes.  Note that this object does not
    # persist.  In other words, it is not a singleton.
    #
    # In addition, if it is called with a trailing 'doc => \$ref'
    # named argument, the reference is populated with the serialized document.
    # This is only really needed for test suites.
    #
    # Here are some of the ways this subroutine might get called:
    #
    # #Object style...
    # $mogrify->transform( $code );
    # $mogrify->transform( $code, doc => \$my_doc );
    #
    # #Functional style...
    # transform( $code );
    # transform( {}, $code );
    # transform( {-foo => bar}, $code );
    # transform( {-foo => bar}, $code, doc => \$my_doc );
    #------------------------------------------------------------------

    my ( $self, $source_code ) = @_ >= 2 ? @_ : ( {}, $_[0] );
    $self = ref $self eq 'HASH' ? __PACKAGE__->new(%{ $self }) : $self;
    return if not defined $source_code;  # If no code, then nothing to do.

    my $config = $self->config();
    my $doc =
        blessed($source_code) && $source_code->isa('Perl::ToPerl6::Document')
            ? $source_code
            : Perl::ToPerl6::Document->new(
                '-source' => $source_code,
                '-program-extensions' => [$config->program_extensions_as_regexes()],
            );

    if ( 0 == $self->transformers() ) {
        Perl::ToPerl6::Exception::Configuration::Generic->throw(
            message => 'There are no enabled transformers.',
        )
    }

    my @transformations = $self->_gather_transformations($doc);

    # Never thought I'd be smuggling myself in one of these.
    #
    if ( $_[-2] and $_[-2] eq 'doc' ) {
        ${$_[-1]} = $doc->serialize;
    }
    unless( ref $source_code ) {
        open my $fh, '>', $source_code . '.pl6'
            or die "Could not write to '$source_code.pl6': $!";
        print $fh $doc->serialize;
        close $fh;
    }
    return @transformations;
}

#=============================================================================
# PRIVATE methods

sub _gather_transformations {
    my ($self, $doc) = @_;

    # Disable exempt code lines, if desired
    if ( not $self->config->force() ) {
        $doc->process_annotations();
    }

    # Evaluate each policy
    my @transformers = $self->config->transformers();
    my @ordered_transformers = _futz_with_policy_order(@transformers);
    my @transformations = map { _transform($_, $doc) } @ordered_transformers;

    # Accumulate statistics
    $self->statistics->accumulate( $doc, \@transformations );

    # If requested, rank transformations by their severity and return the top N.
    if ( @transformations && (my $top = $self->config->top()) ) {
        my $limit = @transformations < $top ? $#transformations : $top-1;
        @transformations = Perl::ToPerl6::Transformation::sort_by_severity(@transformations);
        @transformations = ( reverse @transformations )[ 0 .. $limit ];  #Slicing...
    }

    # Always return transformations sorted by location
    return Perl::ToPerl6::Transformation->sort_by_location(@transformations);
}

#=============================================================================
# PRIVATE functions

sub _transform {
    my ($policy, $doc) = @_;

    return if not $policy->prepare_to_scan_document($doc);

    my $maximum_transformations = $policy->get_maximum_transformations_per_document();
    return if defined $maximum_transformations && $maximum_transformations == 0;

    my @transformations = ();

  TYPE:
    for my $type ( $policy->applies_to() ) {
        my @elements;
        if ($type eq 'PPI::Document') {
            @elements = ($doc);
        }
        else {
            @elements = @{ $doc->find($type) || [] };
        }

      ELEMENT:
        for my $element (@elements) {

            # Evaluate the policy on this $element.  A policy may
            # return zero or more transformations.  We only want the
            # transformations that occur on lines that have not been
            # disabled.

          VIOLATION:
            for my $transformation ( $policy->transform( $element, $doc ) ) {

                my $line = $transformation->location()->[0];
                if ( $doc->line_is_disabled_for_policy($line, $policy) ) {
                    $doc->add_suppressed_transformation($transformation);
                    next VIOLATION;
                }

                push @transformations, $transformation;
                last TYPE if defined $maximum_transformations and @transformations >= $maximum_transformations;
            }
        }
    }

    return @transformations;
}

#-----------------------------------------------------------------------------

sub _futz_with_policy_order {
    # The ProhibitUselessNoCritic policy is another special policy.  It
    # deals with the transformations that *other* Policies produce.  Therefore
    # it needs to be run *after* all the other Policies.  TODO: find
    # a way for Policies to express an ordering preference somehow.

    my @policy_objects = @_;
    my $magical_policy_name = 'Perl::ToPerl6::Transformer::Miscellanea::ProhibitUselessNoCritic';
    my $idx = firstidx {ref $_ eq $magical_policy_name} @policy_objects;
    push @policy_objects, splice @policy_objects, $idx, 1;
    return @policy_objects;
}

#-----------------------------------------------------------------------------

1;



__END__

=pod

=for stopwords DGR INI-style API -params pbp refactored ActivePerl ben Jore
Dolan's Twitter Alexandr Ciornii Ciornii's downloadable

=head1 NAME

Perl::ToPerl6 - Critique Perl source code for best-practices.


=head1 SYNOPSIS

    use Perl::ToPerl6;
    my $file = shift;
    my $mogrify = Perl::ToPerl6->new();
    my @transformations = $mogrify->transform($file);
    print @transformations;


=head1 DESCRIPTION

Perl::ToPerl6 is an extensible framework for creating and applying coding
standards to Perl source code.  Essentially, it is a static source code
analysis engine.  Perl::ToPerl6 is distributed with a number of
L<Perl::ToPerl6::Transformer> modules that attempt to enforce various coding
guidelines.  Most Transformer modules are based on Damian Conway's book B<Perl Best
Practices>.  However, Perl::ToPerl6 is B<not> limited to PBP and will even
support Policies that contradict Conway.  You can enable, disable, and
customize those Polices through the Perl::ToPerl6 interface.  You can also
create new Transformer modules that suit your own tastes.

For a command-line interface to Perl::ToPerl6, see the documentation for
L<perlmogrify>.  If you want to integrate Perl::ToPerl6 with your build process,
L<Test::Perl::ToPerl6> provides an interface that is suitable for test
programs.  Also, L<Test::Perl::ToPerl6::Progressive> is useful for gradually
applying coding standards to legacy code.  For the ultimate convenience (at
the expense of some flexibility) see the L<mogrification> pragma.

If you'd like to try L<Perl::ToPerl6> without installing anything, there is a
web-service available at L<http://perlmogrify.com>.  The web-service does not
yet support all the configuration features that are available in the native
Perl::ToPerl6 API, but it should give you a good idea of what it does.

Also, ActivePerl includes a very slick graphical interface to Perl-ToPerl6
called C<perlmogrify-gui>.  You can get a free community edition of ActivePerl
from L<http://www.activestate.com>.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface will go
through a deprecation cycle.


=head1 CONSTRUCTOR

=over

=item C<< new( [ -profile => $FILE, -severity => $N, -theme => $string, -include => \@PATTERNS, -exclude => \@PATTERNS, -top => $N, -only => $B, -profile-strictness => $PROFILE_STRICTNESS_{WARN|FATAL|QUIET}, -force => $B, -verbose => $N ], -color => $B, -pager => $string, -allow-unsafe => $B, -mogrification-fatal => $B) >>

=item C<< new() >>

Returns a reference to a new Perl::ToPerl6 object.  Most arguments are just
passed directly into L<Perl::ToPerl6::Config>, but I have described them here
as well.  The default value for all arguments can be defined in your
F<.perlmogrifyrc> file.  See the L<"CONFIGURATION"> section for more
information about that.  All arguments are optional key-value pairs as
follows:

B<-profile> is a path to a configuration file. If C<$FILE> is not defined,
Perl::ToPerl6::Config attempts to find a F<.perlmogrifyrc> configuration file in
the current directory, and then in your home directory.  Alternatively, you
can set the C<PERLMOGRIFY> environment variable to point to a file in another
location.  If a configuration file can't be found, or if C<$FILE> is an empty
string, then all Policies will be loaded with their default configuration.
See L<"CONFIGURATION"> for more information.

B<-severity> is the minimum severity level.  Only Transformer modules that have a
severity greater than C<$N> will be applied.  Severity values are integers
ranging from 1 (least severe transformations) to 5 (most severe transformations).  The
default is 5.  For a given C<-profile>, decreasing the C<-severity> will
usually reveal more Transformer transformations. You can set the default value for this
option in your F<.perlmogrifyrc> file.  Users can redefine the severity level
for any Transformer in their F<.perlmogrifyrc> file.  See L<"CONFIGURATION"> for
more information.

If it is difficult for you to remember whether severity "5" is the most or
least restrictive level, then you can use one of these named values:

    SEVERITY NAME   ...is equivalent to...   SEVERITY NUMBER
    --------------------------------------------------------
    -severity => 'gentle'                     -severity => 5
    -severity => 'stern'                      -severity => 4
    -severity => 'harsh'                      -severity => 3
    -severity => 'cruel'                      -severity => 2
    -severity => 'brutal'                     -severity => 1

The names reflect how severely the code is mogrified: a C<gentle>
mogrification reports only the most severe transformations, and so on down to a
C<brutal> mogrification which reports even the most minor transformations.

B<-theme> is special expression that determines which Policies to apply based
on their respective themes.  For example, the following would load only
Policies that have a 'bugs' AND 'pbp' theme:

  my $mogrify = Perl::ToPerl6->new( -theme => 'bugs && pbp' );

Unless the C<-severity> option is explicitly given, setting C<-theme> silently
causes the C<-severity> to be set to 1.  You can set the default value for
this option in your F<.perlmogrifyrc> file.  See the L<"POLICY THEMES"> section
for more information about themes.


B<-include> is a reference to a list of string C<@PATTERNS>.  Transformer modules
that match at least one C<m/$PATTERN/ixms> will always be loaded, irrespective
of all other settings.  For example:

    my $mogrify = Perl::ToPerl6->new(-include => ['layout'] -severity => 4);

This would cause Perl::ToPerl6 to apply all the C<CodeLayout::*> Transformer modules
even though they have a severity level that is less than 4. You can set the
default value for this option in your F<.perlmogrifyrc> file.  You can also use
C<-include> in conjunction with the C<-exclude> option.  Note that C<-exclude>
takes precedence over C<-include> when a Transformer matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Transformer modules
that match at least one C<m/$PATTERN/ixms> will not be loaded, irrespective of
all other settings.  For example:

    my $mogrify = Perl::ToPerl6->new(-exclude => ['strict'] -severity => 1);

This would cause Perl::ToPerl6 to not apply the C<RequireUseStrict> and
C<ProhibitNoStrict> Transformer modules even though they have a severity level that
is greater than 1.  You can set the default value for this option in your
F<.perlmogrifyrc> file.  You can also use C<-exclude> in conjunction with the
C<-include> option.  Note that C<-exclude> takes precedence over C<-include>
when a Transformer matches both patterns.

B<-single-policy> is a string C<PATTERN>.  Only one policy that matches
C<m/$PATTERN/ixms> will be used.  Policies that do not match will be excluded.
This option has precedence over the C<-severity>, C<-theme>, C<-include>,
C<-exclude>, and C<-only> options.  You can set the default value for this
option in your F<.perlmogrifyrc> file.

B<-top> is the maximum number of Transformations to return when ranked by their
severity levels.  This must be a positive integer.  Transformations are still
returned in the order that they occur within the file. Unless the C<-severity>
option is explicitly given, setting C<-top> silently causes the C<-severity>
to be set to 1.  You can set the default value for this option in your
F<.perlmogrifyrc> file.

B<-only> is a boolean value.  If set to a true value, Perl::ToPerl6 will only
choose from Policies that are mentioned in the user's profile.  If set to a
false value (which is the default), then Perl::ToPerl6 chooses from all the
Policies that it finds at your site. You can set the default value for this
option in your F<.perlmogrifyrc> file.

B<-profile-strictness> is an enumerated value, one of
L<Perl::ToPerl6::Utils::Constants/"$PROFILE_STRICTNESS_WARN"> (the default),
L<Perl::ToPerl6::Utils::Constants/"$PROFILE_STRICTNESS_FATAL">, and
L<Perl::ToPerl6::Utils::Constants/"$PROFILE_STRICTNESS_QUIET">.  If set to
L<Perl::ToPerl6::Utils::Constants/"$PROFILE_STRICTNESS_FATAL">, Perl::ToPerl6
will make certain warnings about problems found in a F<.perlmogrifyrc> or file
specified via the B<-profile> option fatal. For example, Perl::ToPerl6 normally
only C<warn>s about profiles referring to non-existent Policies, but this
value makes this situation fatal.  Correspondingly,
L<Perl::ToPerl6::Utils::Constants/"$PROFILE_STRICTNESS_QUIET"> makes
Perl::ToPerl6 shut up about these things.

B<-force> is a boolean value that controls whether Perl::ToPerl6 observes the
magical C<"## no mogrify"> annotations in your code. If set to a true value,
Perl::ToPerl6 will analyze all code.  If set to a false value (which is the
default) Perl::ToPerl6 will ignore code that is tagged with these annotations.
See L<"BENDING THE RULES"> for more information.  You can set the default
value for this option in your F<.perlmogrifyrc> file.

B<-verbose> can be a positive integer (from 1 to 11), or a literal format
specification.  See L<Perl::ToPerl6::Transformation|Perl::ToPerl6::Transformation> for an
explanation of format specifications.  You can set the default value for this
option in your F<.perlmogrifyrc> file.

B<-unsafe> directs Perl::ToPerl6 to allow the use of Policies that are marked
as "unsafe" by the author.  Such transformers may compile untrusted code or do
other nefarious things.

B<-color> and B<-pager> are not used by Perl::ToPerl6 but is provided for the
benefit of L<perlmogrify|perlmogrify>.

B<-mogrification-fatal> is not used by Perl::ToPerl6 but is provided for the
benefit of L<mogrification|mogrification>.

B<-color-severity-highest>, B<-color-severity-high>, B<-color-severity-
medium>, B<-color-severity-low>, and B<-color-severity-lowest> are not used by
Perl::ToPerl6, but are provided for the benefit of L<perlmogrify|perlmogrify>.
Each is set to the Term::ANSIColor color specification to be used to display
transformations of the corresponding severity.

B<-files-with-transformations> and B<-files-without-transformations> are not used by
Perl::ToPerl6, but are provided for the benefit of L<perlmogrify|perlmogrify>, to
cause only the relevant filenames to be displayed.

=back


=head1 METHODS

=over

=item C<transform( $source_code )>

Runs the C<$source_code> through the Perl::ToPerl6 engine using all the
Policies that have been loaded into this engine.  If C<$source_code> is a
scalar reference, then it is treated as a string of actual Perl code.  If
C<$source_code> is a reference to an instance of L<PPI::Document>, then that
instance is used directly. Otherwise, it is treated as a path to a local file
containing Perl code.  This method returns a list of
L<Perl::ToPerl6::Transformation> objects for each transformation of the loaded Policies.
The list is sorted in the order that the Transformations appear in the code.  If
there are no transformations, this method returns an empty list.

=item C<< apply_transform( -policy => $policy_name, -params => \%param_hash ) >>

Creates a Transformer object and loads it into this ToPerl6.  If the object cannot
be instantiated, it will throw a fatal exception.  Otherwise, it returns a
reference to this ToPerl6.

B<-policy> is the name of a L<Perl::ToPerl6::Transformer> subclass module.  The
C<'Perl::ToPerl6::Transformer'> portion of the name can be omitted for brevity.
This argument is required.

B<-params> is an optional reference to a hash of Transformer parameters. The
contents of this hash reference will be passed into to the constructor of the
Transformer module.  See the documentation in the relevant Transformer module for a
description of the arguments it supports.

=item C< transformers() >

Returns a list containing references to all the Transformer objects that have been
loaded into this engine.  Objects will be in the order that they were loaded.

=item C< config() >

Returns the L<Perl::ToPerl6::Config> object that was created for or given to
this ToPerl6.

=item C< statistics() >

Returns the L<Perl::ToPerl6::Statistics> object that was created for this
ToPerl6.  The Statistics object accumulates data for all files that are
analyzed by this ToPerl6.

=back


=head1 FUNCTIONAL INTERFACE

For those folks who prefer to have a functional interface, The C<transform>
method can be exported on request and called as a static function.  If the
first argument is a hashref, its contents are used to construct a new
Perl::ToPerl6 object internally.  The keys of that hash should be the same as
those supported by the C<Perl::ToPerl6::new()> method.  Here are some examples:

    use Perl::ToPerl6 qw(transform);

    # Use default parameters...
    @transformations = transform( $some_file );

    # Use custom parameters...
    @transformations = transform( {-severity => 2}, $some_file );

    # As a one-liner
    %> perl -MPerl::ToPerl6=transform -e 'print transform(shift)' some_file.pm

None of the other object-methods are currently supported as static
functions.  Sorry.


=head1 CONFIGURATION

Most of the settings for Perl::ToPerl6 and each of the Transformer modules can be
controlled by a configuration file.  The default configuration file is called
F<.perlmogrifyrc>.  Perl::ToPerl6 will look for this file in the current
directory first, and then in your home directory. Alternatively, you can set
the C<PERLMOGRIFY> environment variable to explicitly point to a different file
in another location.  If none of these files exist, and the C<-profile> option
is not given to the constructor, then all the modules that are found in the
Perl::ToPerl6::Transformer namespace will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks that
contain key-value pairs separated by '='. Comments should start with '#' and
can be placed on a separate line or after the name-value pairs if you desire.

Default settings for Perl::ToPerl6 itself can be set B<before the first named
block.> For example, putting any or all of these at the top of your
configuration file will set the default value for the corresponding
constructor argument.

    severity  = 3                                     #Integer or named level
    only      = 1                                     #Zero or One
    force     = 0                                     #Zero or One
    verbose   = 4                                     #Integer or format spec
    top       = 50                                    #A positive integer
    theme     = (pbp || security) && bugs             #A theme expression
    include   = NamingConventions ClassHierarchies    #Space-delimited list
    exclude   = Variables  Modules::RequirePackage    #Space-delimited list
    mogrification-fatal = 1                           #Zero or One
    color     = 1                                     #Zero or One
    allow-unsafe = 1                                  #Zero or One
    pager     = less                                  #pager to pipe output to

The remainder of the configuration file is a series of blocks like this:

    [Perl::ToPerl6::Transformer::Category::TransformerName]
    severity = 1
    set_themes = foo bar
    add_themes = baz
    maximum_transformations_per_document = 57
    arg1 = value1
    arg2 = value2

C<Perl::ToPerl6::Transformer::Category::TransformerName> is the full name of a module
that implements the policy.  The Transformer modules distributed with Perl::ToPerl6
have been grouped into categories according to the table of contents in Damian
Conway's book B<Perl Best Practices>. For brevity, you can omit the
C<'Perl::ToPerl6::Transformer'> part of the module name.

C<severity> is the level of importance you wish to assign to the Transformer.  All
Transformer modules are defined with a default severity value ranging from 1 (least
severe) to 5 (most severe).  However, you may disagree with the default
severity and choose to give it a higher or lower severity, based on your own
coding philosophy.  You can set the C<severity> to an integer from 1 to 5, or
use one of the equivalent names:

    SEVERITY NAME ...is equivalent to... SEVERITY NUMBER
    ----------------------------------------------------
    gentle                                             5
    stern                                              4
    harsh                                              3
    cruel                                              2
    brutal                                             1

The names reflect how severely the code is mogrified: a C<gentle>
mogrification reports only the most severe transformations, and so on down to a
C<brutal> mogrification which reports even the most minor transformations.

C<set_themes> sets the theme for the Transformer and overrides its default theme.
The argument is a string of one or more whitespace-delimited alphanumeric
words.  Themes are case-insensitive.  See L<"POLICY THEMES"> for more
information.

C<add_themes> appends to the default themes for this Transformer.  The argument is
a string of one or more whitespace-delimited words. Themes are case-
insensitive.  See L<"POLICY THEMES"> for more information.

C<maximum_transformations_per_document> limits the number of Transformations the Transformer
will return for a given document.  Some Policies have a default limit; see the
documentation for the individual Policies to see whether there is one.  To
force a Transformer to not have a limit, specify "no_limit" or the empty string for
the value of this parameter.

The remaining key-value pairs are configuration parameters that will be passed
into the constructor for that Transformer.  The constructors for most Transformer
objects do not support arguments, and those that do should have reasonable
defaults.  See the documentation on the appropriate Transformer module for more
details.

Instead of redefining the severity for a given Transformer, you can completely
disable a Transformer by prepending a '-' to the name of the module in your
configuration file.  In this manner, the Transformer will never be loaded,
regardless of the C<-severity> given to the Perl::ToPerl6 constructor.

A simple configuration might look like this:

    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequireUseStrict]
    severity = 5

    [TestingAndDebugging::RequireUseWarnings]
    severity = 5

    #--------------------------------------------------------------
    # I think these are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    severity = 2

    [ControlStructures::ProhibitPostfixControls]
    allow = if unless  # My custom configuration
    severity = cruel   # Same as "severity = 2"

    #--------------------------------------------------------------
    # Give these transformers a custom theme.  I can activate just
    # these transformers by saying `perlmogrify -theme larry`

    [Modules::RequireFilenameMatchesPackage]
    add_themes = larry

    [TestingAndDebugging::RequireTestLables]
    add_themes = larry curly moe

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::Capitalization]
    [-ValuesAndExpressions::ProhibitMagicNumbers]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity,
    # so no additional configuration is required for them.

For additional configuration examples, see the F<perlmogrifyrc> file that is
included in this F<examples> directory of this distribution.

Damian Conway's own Perl::ToPerl6 configuration is also included in this
distribution as F<examples/perlmogrifyrc-conway>.


=head1 THE POLICIES

A large number of Transformer modules are distributed with Perl::ToPerl6. They are
described briefly in the companion document L<Perl::ToPerl6::TransformerSummary> and
in more detail in the individual modules themselves.  Say C<"perlmogrify -doc
PATTERN"> to see the perldoc for all Transformer modules that match the regex
C<m/PATTERN/ixms>

There are a number of distributions of additional transformers on CPAN. If
L<Perl::ToPerl6> doesn't contain a policy that you want, some one may have
already written it.  See the L</"SEE ALSO"> section below for a list of some
of these distributions.


=head1 POLICY THEMES

Each Transformer is defined with one or more "themes".  Themes can be used to
create arbitrary groups of Policies.  They are intended to provide an
alternative mechanism for selecting your preferred set of Policies. For
example, you may wish disable a certain subset of Policies when analyzing test
programs.  Conversely, you may wish to enable only a specific subset of
Policies when analyzing modules.

The Policies that ship with Perl::ToPerl6 have been broken into the following
themes.  This is just our attempt to provide some basic logical groupings.
You are free to invent new themes that suit your needs.

    THEME             DESCRIPTION
    --------------------------------------------------------------------------
    core              All transformers that ship with Perl::ToPerl6
    pbp               Policies that come directly from "Perl Best Practices"
    bugs              Policies that that prevent or reveal bugs
    certrec           Policies that CERT recommends
    certrule          Policies that CERT considers rules
    maintenance       Policies that affect the long-term health of the code
    cosmetic          Policies that only have a superficial effect
    complexity        Policies that specificaly relate to code complexity
    security          Policies that relate to security issues
    tests             Policies that are specific to test programs


Any Transformer may fit into multiple themes.  Say C<"perlmogrify -list"> to get a
listing of all available Policies and the themes that are associated with each
one.  You can also change the theme for any Transformer in your F<.perlmogrifyrc>
file.  See the L<"CONFIGURATION"> section for more information about that.

Using the C<-theme> option, you can create an arbitrarily complex rule that
determines which Policies will be loaded.  Precedence is the same as regular
Perl code, and you can use parentheses to enforce precedence as well.
Supported operators are:

    Operator    Alternative    Example
    -----------------------------------------------------------------
    &&          and            'pbp && core'
    ||          or             'pbp || (bugs && security)'
    !           not            'pbp && ! (portability || complexity)'

Theme names are case-insensitive.  If the C<-theme> is set to an empty string,
then it evaluates as true all Policies.


=head1 BENDING THE RULES

Perl::ToPerl6 takes a hard-line approach to your code: either you comply or you
don't.  In the real world, it is not always practical (nor even possible) to
fully comply with coding standards.  In such cases, it is wise to show that
you are knowingly violating the standards and that you have a Damn Good Reason
(DGR) for doing so.

To help with those situations, you can direct Perl::ToPerl6 to ignore certain
lines or blocks of code by using annotations:

    require 'LegacyLibaray1.pl';  ## no mogrify
    require 'LegacyLibrary2.pl';  ## no mogrify

    for my $element (@list) {

        ## no mogrify

        $foo = "";               #Violates 'ProhibitEmptyQuotes'
        $barf = bar() if $foo;   #Violates 'ProhibitPostfixControls'
        #Some more evil code...

        ## use mogrify

        #Some good code...
        do_something($_);
    }

The C<"## no mogrify"> annotations direct Perl::ToPerl6 to ignore the remaining
lines of code until a C<"## use mogrify"> annotation is found. If the C<"## no
mogrify"> annotation is on the same line as a code statement, then only that
line of code is overlooked.  To direct perlmogrify to ignore the C<"## no
mogrify"> annotations, use the C<--force> option.

A bare C<"## no mogrify"> annotation disables all the active Policies.  If you
wish to disable only specific Policies, add a list of Transformer names as
arguments, just as you would for the C<"no strict"> or C<"no warnings">
pragmas.  For example, this would disable the C<ProhibitEmptyQuotes> and
C<ProhibitPostfixControls> transformers until the end of the block or until the
next C<"## use mogrify"> annotation (whichever comes first):

    ## no mogrify (EmptyQuotes, PostfixControls)

    # Now exempt from ValuesAndExpressions::ProhibitEmptyQuotes
    $foo = "";

    # Now exempt ControlStructures::ProhibitPostfixControls
    $barf = bar() if $foo;

    # Still subjected to ValuesAndExpression::RequireNumberSeparators
    $long_int = 10000000000;

Since the Transformer names are matched against the C<"## no mogrify"> arguments as
regular expressions, you can abbreviate the Transformer names or disable an entire
family of Policies in one shot like this:

    ## no mogrify (NamingConventions)

    # Now exempt from NamingConventions::Capitalization
    my $camelHumpVar = 'foo';

    # Now exempt from NamingConventions::Capitalization
    sub camelHumpSub {}

The argument list must be enclosed in parentheses and must contain one or more
comma-separated barewords (e.g. don't use quotes).  The C<"## no mogrify">
annotations can be nested, and Policies named by an inner annotation will be
disabled along with those already disabled an outer annotation.

Some Policies like C<Subroutines::ProhibitExcessComplexity> apply to an entire
block of code.  In those cases, the C<"## no mogrify"> annotation must appear
on the line where the transformation is reported.  For example:

    sub complicated_function {  ## no mogrify (ProhibitExcessComplexity)
        # Your code here...
    }

Policies such as C<Documentation::RequirePodSections> apply to the entire
document, in which case transformations are reported at line 1.

Use this feature wisely.  C<"## no mogrify"> annotations should be used in the
smallest possible scope, or only on individual lines of code. And you should
always be as specific as possible about which Policies you want to disable
(i.e. never use a bare C<"## no mogrify">).  If Perl::ToPerl6 complains about
your code, try and find a compliant solution before resorting to this feature.


=head1 THE L<Perl::ToPerl6> PHILOSOPHY

Coding standards are deeply personal and highly subjective.  The goal of
Perl::ToPerl6 is to help you write code that conforms with a set of best
practices.  Our primary goal is not to dictate what those practices are, but
rather, to implement the practices discovered by others.  Ultimately, you make
the rules -- Perl::ToPerl6 is merely a tool for encouraging consistency.  If
there is a policy that you think is important or that we have overlooked, we
would be very grateful for contributions, or you can simply load your own
private set of transformers into Perl::ToPerl6.


=head1 EXTENDING THE MOGRIFIER

The modular design of Perl::ToPerl6 is intended to facilitate the addition of
new Policies.  You'll need to have some understanding of L<PPI>, but most
Transformer modules are pretty straightforward and only require about 20 lines of
code.  Please see the L<Perl::ToPerl6::DEVELOPER> file included in this
distribution for a step-by-step demonstration of how to create new Transformer
modules.

If you develop any new Transformer modules, feel free to send them to C<<
<team@perlmogrify.com> >> and I'll be happy to consider adding them into the
Perl::ToPerl6 distribution.  Or if you would like to work on the Perl::ToPerl6
project directly, you can fork our repository at L<http://github.com/Perl-
ToPerl6/Perl- ToPerl6.git>.

The Perl::ToPerl6 team is also available for hire.  If your organization has
its own coding standards, we can create custom Policies to enforce your local
guidelines.  Or if your code base is prone to a particular defect pattern, we
can design Policies that will help you catch those costly defects B<before>
they go into production. To discuss your needs with the Perl::ToPerl6 team,
just contact C<< <team@perlmogrify.com> >>.


=head1 PREREQUISITES

Perl::ToPerl6 requires the following modules:

L<B::Keywords>

L<Config::Tiny>

L<Exception::Class>

L<File::HomeDir>

L<File::Spec>

L<File::Spec::Unix>

L<File::Which>

L<IO::String>

L<List::MoreUtils>

L<List::Util>

L<Module::Pluggable>

L<PPI|PPI>

L<Pod::PlainText>

L<Pod::Select>

L<Pod::Usage>

L<Readonly>

L<Scalar::Util>

L<String::Format>

L<Task::Weaken>

L<Term::ANSIColor>

L<Text::ParseWords>

L<version|version>


=head1 CONTACTING THE DEVELOPMENT TEAM

You are encouraged to subscribe to the mailing list; send a message to
L<mailto:users-subscribe@perlmogrify.tigris.org>.  To prevent spam, you may be
required to register for a user account with Tigris.org before being allowed
to post messages to the mailing list. See also the mailing list archives at
L<http://perlmogrify.tigris.org/servlets/SummarizeList?listName=users>. At
least one member of the development team is usually hanging around in
L<irc://irc.perl.org/#perlmogrify> and you can follow Perl::ToPerl6 on Twitter,
at L<https://twitter.com/perlmogrify>.


=head1 SEE ALSO

There are a number of distributions of additional Policies available. A few
are listed here:

L<Perl::ToPerl6::More>

L<Perl::ToPerl6::Bangs>

L<Perl::ToPerl6::Lax>

L<Perl::ToPerl6::StricterSubs>

L<Perl::ToPerl6::Swift>

L<Perl::ToPerl6::Tics>

These distributions enable you to use Perl::ToPerl6 in your unit tests:

L<Test::Perl::ToPerl6>

L<Test::Perl::ToPerl6::Progressive>

There is also a distribution that will install all the Perl::ToPerl6 related
modules known to the development team:

L<Task::Perl::ToPerl6>


=head1 BUGS

Scrutinizing Perl code is hard for humans, let alone machines.  If you find
any bugs, particularly false-positives or false-negatives from a
Perl::ToPerl6::Transformer, please submit them at L<https://github.com/Perl-ToPerl6
/Perl-ToPerl6/issues>.  Thanks.

=head1 CREDITS

Adam Kennedy - For creating L<PPI>, the heart and soul of L<Perl::ToPerl6>.

Damian Conway - For writing B<Perl Best Practices>, finally :)

Chris Dolan - For contributing the best features and Transformer modules.

Andy Lester - Wise sage and master of all-things-testing.

Elliot Shank - The self-proclaimed quality freak.

Giuseppe Maxia - For all the great ideas and positive encouragement.

and Sharon, my wife - For putting up with my all-night code sessions.

Thanks also to the Perl Foundation for providing a grant to support Chris
Dolan's project to implement twenty PBP transformers.
L<http://www.perlfoundation.org/april_1_2007_new_grant_awards>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2013 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

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
