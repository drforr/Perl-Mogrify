# NAME

Perl::Mogrify - Critique Perl source code for best-practices.

# SYNOPSIS

    use Perl::Mogrify;
    my $file = shift;
    my $critic = Perl::Mogrify->new();
    my @violations = $critic->critique($file);
    print @violations;

# DESCRIPTION

Perl::Mogrify is an extensible framework for creating and applying coding
standards to Perl source code.  Essentially, it is a static source code
analysis engine.  Perl::Mogrify is distributed with a number of
[Perl::Mogrify::Enforcer](https://metacpan.org/pod/Perl::Mogrify::Enforcer) modules that attempt to enforce various coding
guidelines.  Most Enforcer modules are based on Damian Conway's book **Perl Best
Practices**.  However, Perl::Mogrify is **not** limited to PBP and will even
support Policies that contradict Conway.  You can enable, disable, and
customize those Polices through the Perl::Mogrify interface.  You can also
create new Enforcer modules that suit your own tastes.

For a command-line interface to Perl::Mogrify, see the documentation for
[perlcritic](https://metacpan.org/pod/perlcritic).  If you want to integrate Perl::Mogrify with your build process,
[Test::Perl::Mogrify](https://metacpan.org/pod/Test::Perl::Mogrify) provides an interface that is suitable for test
programs.  Also, [Test::Perl::Mogrify::Progressive](https://metacpan.org/pod/Test::Perl::Mogrify::Progressive) is useful for gradually
applying coding standards to legacy code.  For the ultimate convenience (at
the expense of some flexibility) see the [criticism](https://metacpan.org/pod/criticism) pragma.

If you'd like to try [Perl::Mogrify](https://metacpan.org/pod/Perl::Mogrify) without installing anything, there is a
web-service available at [http://perlcritic.com](http://perlcritic.com).  The web-service does not
yet support all the configuration features that are available in the native
Perl::Mogrify API, but it should give you a good idea of what it does.

Also, ActivePerl includes a very slick graphical interface to Perl-Mogrify
called `perlcritic-gui`.  You can get a free community edition of ActivePerl
from [http://www.activestate.com](http://www.activestate.com).

# INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface will go
through a deprecation cycle.

# CONSTRUCTOR

- `new( [ -profile => $FILE, -severity => $N, -theme => $string, -include => \@PATTERNS, -exclude => \@PATTERNS, -top => $N, -only => $B, -profile-strictness => $PROFILE_STRICTNESS_{WARN|FATAL|QUIET}, -force => $B, -verbose => $N ], -color => $B, -pager => $string, -allow-unsafe => $B, -criticism-fatal => $B)`
- `new()`

    Returns a reference to a new Perl::Mogrify object.  Most arguments are just
    passed directly into [Perl::Mogrify::Config](https://metacpan.org/pod/Perl::Mogrify::Config), but I have described them here
    as well.  The default value for all arguments can be defined in your
    `.perlcriticrc` file.  See the ["CONFIGURATION"](#configuration) section for more
    information about that.  All arguments are optional key-value pairs as
    follows:

    **-profile** is a path to a configuration file. If `$FILE` is not defined,
    Perl::Mogrify::Config attempts to find a `.perlcriticrc` configuration file in
    the current directory, and then in your home directory.  Alternatively, you
    can set the `PERLCRITIC` environment variable to point to a file in another
    location.  If a configuration file can't be found, or if `$FILE` is an empty
    string, then all Policies will be loaded with their default configuration.
    See ["CONFIGURATION"](#configuration) for more information.

    **-severity** is the minimum severity level.  Only Enforcer modules that have a
    severity greater than `$N` will be applied.  Severity values are integers
    ranging from 1 (least severe violations) to 5 (most severe violations).  The
    default is 5.  For a given `-profile`, decreasing the `-severity` will
    usually reveal more Enforcer violations. You can set the default value for this
    option in your `.perlcriticrc` file.  Users can redefine the severity level
    for any Enforcer in their `.perlcriticrc` file.  See ["CONFIGURATION"](#configuration) for
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

    The names reflect how severely the code is criticized: a `gentle` criticism
    reports only the most severe violations, and so on down to a `brutal`
    criticism which reports even the most minor violations.

    **-theme** is special expression that determines which Policies to apply based
    on their respective themes.  For example, the following would load only
    Policies that have a 'bugs' AND 'pbp' theme:

        my $critic = Perl::Mogrify->new( -theme => 'bugs && pbp' );

    Unless the `-severity` option is explicitly given, setting `-theme` silently
    causes the `-severity` to be set to 1.  You can set the default value for
    this option in your `.perlcriticrc` file.  See the ["POLICY THEMES"](#policy-themes) section
    for more information about themes.

    **-include** is a reference to a list of string `@PATTERNS`.  Enforcer modules
    that match at least one `m/$PATTERN/ixms` will always be loaded, irrespective
    of all other settings.  For example:

        my $critic = Perl::Mogrify->new(-include => ['layout'] -severity => 4);

    This would cause Perl::Mogrify to apply all the `CodeLayout::*` Enforcer modules
    even though they have a severity level that is less than 4. You can set the
    default value for this option in your `.perlcriticrc` file.  You can also use
    `-include` in conjunction with the `-exclude` option.  Note that `-exclude`
    takes precedence over `-include` when a Enforcer matches both patterns.

    **-exclude** is a reference to a list of string `@PATTERNS`.  Enforcer modules
    that match at least one `m/$PATTERN/ixms` will not be loaded, irrespective of
    all other settings.  For example:

        my $critic = Perl::Mogrify->new(-exclude => ['strict'] -severity => 1);

    This would cause Perl::Mogrify to not apply the `RequireUseStrict` and
    `ProhibitNoStrict` Enforcer modules even though they have a severity level that
    is greater than 1.  You can set the default value for this option in your
    `.perlcriticrc` file.  You can also use `-exclude` in conjunction with the
    `-include` option.  Note that `-exclude` takes precedence over `-include`
    when a Enforcer matches both patterns.

    **-single-policy** is a string `PATTERN`.  Only one policy that matches
    `m/$PATTERN/ixms` will be used.  Policies that do not match will be excluded.
    This option has precedence over the `-severity`, `-theme`, `-include`,
    `-exclude`, and `-only` options.  You can set the default value for this
    option in your `.perlcriticrc` file.

    **-top** is the maximum number of Violations to return when ranked by their
    severity levels.  This must be a positive integer.  Violations are still
    returned in the order that they occur within the file. Unless the `-severity`
    option is explicitly given, setting `-top` silently causes the `-severity`
    to be set to 1.  You can set the default value for this option in your
    `.perlcriticrc` file.

    **-only** is a boolean value.  If set to a true value, Perl::Mogrify will only
    choose from Policies that are mentioned in the user's profile.  If set to a
    false value (which is the default), then Perl::Mogrify chooses from all the
    Policies that it finds at your site. You can set the default value for this
    option in your `.perlcriticrc` file.

    **-profile-strictness** is an enumerated value, one of
    ["$PROFILE\_STRICTNESS\_WARN" in Perl::Mogrify::Utils::Constants](https://metacpan.org/pod/Perl::Mogrify::Utils::Constants#PROFILE_STRICTNESS_WARN) (the default),
    ["$PROFILE\_STRICTNESS\_FATAL" in Perl::Mogrify::Utils::Constants](https://metacpan.org/pod/Perl::Mogrify::Utils::Constants#PROFILE_STRICTNESS_FATAL), and
    ["$PROFILE\_STRICTNESS\_QUIET" in Perl::Mogrify::Utils::Constants](https://metacpan.org/pod/Perl::Mogrify::Utils::Constants#PROFILE_STRICTNESS_QUIET).  If set to
    ["$PROFILE\_STRICTNESS\_FATAL" in Perl::Mogrify::Utils::Constants](https://metacpan.org/pod/Perl::Mogrify::Utils::Constants#PROFILE_STRICTNESS_FATAL), Perl::Mogrify
    will make certain warnings about problems found in a `.perlcriticrc` or file
    specified via the **-profile** option fatal. For example, Perl::Mogrify normally
    only `warn`s about profiles referring to non-existent Policies, but this
    value makes this situation fatal.  Correspondingly,
    ["$PROFILE\_STRICTNESS\_QUIET" in Perl::Mogrify::Utils::Constants](https://metacpan.org/pod/Perl::Mogrify::Utils::Constants#PROFILE_STRICTNESS_QUIET) makes
    Perl::Mogrify shut up about these things.

    **-force** is a boolean value that controls whether Perl::Mogrify observes the
    magical `"## no critic"` annotations in your code. If set to a true value,
    Perl::Mogrify will analyze all code.  If set to a false value (which is the
    default) Perl::Mogrify will ignore code that is tagged with these annotations.
    See ["BENDING THE RULES"](#bending-the-rules) for more information.  You can set the default
    value for this option in your `.perlcriticrc` file.

    **-verbose** can be a positive integer (from 1 to 11), or a literal format
    specification.  See [Perl::Mogrify::Violation](https://metacpan.org/pod/Perl::Mogrify::Violation) for an
    explanation of format specifications.  You can set the default value for this
    option in your `.perlcriticrc` file.

    **-unsafe** directs Perl::Mogrify to allow the use of Policies that are marked
    as "unsafe" by the author.  Such policies may compile untrusted code or do
    other nefarious things.

    **-color** and **-pager** are not used by Perl::Mogrify but is provided for the
    benefit of [perlcritic](https://metacpan.org/pod/perlcritic).

    **-criticism-fatal** is not used by Perl::Mogrify but is provided for the
    benefit of [criticism](https://metacpan.org/pod/criticism).

    **-color-severity-highest**, **-color-severity-high**, **-color-severity-
    medium**, **-color-severity-low**, and **-color-severity-lowest** are not used by
    Perl::Mogrify, but are provided for the benefit of [perlcritic](https://metacpan.org/pod/perlcritic).
    Each is set to the Term::ANSIColor color specification to be used to display
    violations of the corresponding severity.

    **-files-with-violations** and **-files-without-violations** are not used by
    Perl::Mogrify, but are provided for the benefit of [perlcritic](https://metacpan.org/pod/perlcritic), to
    cause only the relevant filenames to be displayed.

# METHODS

- `critique( $source_code )`

    Runs the `$source_code` through the Perl::Mogrify engine using all the
    Policies that have been loaded into this engine.  If `$source_code` is a
    scalar reference, then it is treated as a string of actual Perl code.  If
    `$source_code` is a reference to an instance of [PPI::Document](https://metacpan.org/pod/PPI::Document), then that
    instance is used directly. Otherwise, it is treated as a path to a local file
    containing Perl code.  This method returns a list of
    [Perl::Mogrify::Violation](https://metacpan.org/pod/Perl::Mogrify::Violation) objects for each violation of the loaded Policies.
    The list is sorted in the order that the Violations appear in the code.  If
    there are no violations, this method returns an empty list.

- `add_policy( -policy => $policy_name, -params => \%param_hash )`

    Creates a Enforcer object and loads it into this Mogrify.  If the object cannot
    be instantiated, it will throw a fatal exception.  Otherwise, it returns a
    reference to this Mogrify.

    **-policy** is the name of a [Perl::Mogrify::Enforcer](https://metacpan.org/pod/Perl::Mogrify::Enforcer) subclass module.  The
    `'Perl::Mogrify::Enforcer'` portion of the name can be omitted for brevity.
    This argument is required.

    **-params** is an optional reference to a hash of Enforcer parameters. The
    contents of this hash reference will be passed into to the constructor of the
    Enforcer module.  See the documentation in the relevant Enforcer module for a
    description of the arguments it supports.

- ` policies() `

    Returns a list containing references to all the Enforcer objects that have been
    loaded into this engine.  Objects will be in the order that they were loaded.

- ` config() `

    Returns the [Perl::Mogrify::Config](https://metacpan.org/pod/Perl::Mogrify::Config) object that was created for or given to
    this Mogrify.

- ` statistics() `

    Returns the [Perl::Mogrify::Statistics](https://metacpan.org/pod/Perl::Mogrify::Statistics) object that was created for this
    Mogrify.  The Statistics object accumulates data for all files that are
    analyzed by this Mogrify.

# FUNCTIONAL INTERFACE

For those folks who prefer to have a functional interface, The `critique`
method can be exported on request and called as a static function.  If the
first argument is a hashref, its contents are used to construct a new
Perl::Mogrify object internally.  The keys of that hash should be the same as
those supported by the `Perl::Mogrify::new()` method.  Here are some examples:

    use Perl::Mogrify qw(critique);

    # Use default parameters...
    @violations = critique( $some_file );

    # Use custom parameters...
    @violations = critique( {-severity => 2}, $some_file );

    # As a one-liner
    %> perl -MPerl::Mogrify=critique -e 'print critique(shift)' some_file.pm

None of the other object-methods are currently supported as static
functions.  Sorry.

# CONFIGURATION

Most of the settings for Perl::Mogrify and each of the Enforcer modules can be
controlled by a configuration file.  The default configuration file is called
`.perlcriticrc`.  Perl::Mogrify will look for this file in the current
directory first, and then in your home directory. Alternatively, you can set
the `PERLCRITIC` environment variable to explicitly point to a different file
in another location.  If none of these files exist, and the `-profile` option
is not given to the constructor, then all the modules that are found in the
Perl::Mogrify::Enforcer namespace will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks that
contain key-value pairs separated by '='. Comments should start with '#' and
can be placed on a separate line or after the name-value pairs if you desire.

Default settings for Perl::Mogrify itself can be set **before the first named
block.** For example, putting any or all of these at the top of your
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
    criticism-fatal = 1                               #Zero or One
    color     = 1                                     #Zero or One
    allow-unsafe = 1                                  #Zero or One
    pager     = less                                  #pager to pipe output to

The remainder of the configuration file is a series of blocks like this:

    [Perl::Mogrify::Enforcer::Category::PolicyName]
    severity = 1
    set_themes = foo bar
    add_themes = baz
    maximum_violations_per_document = 57
    arg1 = value1
    arg2 = value2

`Perl::Mogrify::Enforcer::Category::PolicyName` is the full name of a module
that implements the policy.  The Enforcer modules distributed with Perl::Mogrify
have been grouped into categories according to the table of contents in Damian
Conway's book **Perl Best Practices**. For brevity, you can omit the
`'Perl::Mogrify::Enforcer'` part of the module name.

`severity` is the level of importance you wish to assign to the Enforcer.  All
Enforcer modules are defined with a default severity value ranging from 1 (least
severe) to 5 (most severe).  However, you may disagree with the default
severity and choose to give it a higher or lower severity, based on your own
coding philosophy.  You can set the `severity` to an integer from 1 to 5, or
use one of the equivalent names:

    SEVERITY NAME ...is equivalent to... SEVERITY NUMBER
    ----------------------------------------------------
    gentle                                             5
    stern                                              4
    harsh                                              3
    cruel                                              2
    brutal                                             1

The names reflect how severely the code is criticized: a `gentle` criticism
reports only the most severe violations, and so on down to a `brutal`
criticism which reports even the most minor violations.

`set_themes` sets the theme for the Enforcer and overrides its default theme.
The argument is a string of one or more whitespace-delimited alphanumeric
words.  Themes are case-insensitive.  See ["POLICY THEMES"](#policy-themes) for more
information.

`add_themes` appends to the default themes for this Enforcer.  The argument is
a string of one or more whitespace-delimited words. Themes are case-
insensitive.  See ["POLICY THEMES"](#policy-themes) for more information.

`maximum_violations_per_document` limits the number of Violations the Enforcer
will return for a given document.  Some Policies have a default limit; see the
documentation for the individual Policies to see whether there is one.  To
force a Enforcer to not have a limit, specify "no\_limit" or the empty string for
the value of this parameter.

The remaining key-value pairs are configuration parameters that will be passed
into the constructor for that Enforcer.  The constructors for most Enforcer
objects do not support arguments, and those that do should have reasonable
defaults.  See the documentation on the appropriate Enforcer module for more
details.

Instead of redefining the severity for a given Enforcer, you can completely
disable a Enforcer by prepending a '-' to the name of the module in your
configuration file.  In this manner, the Enforcer will never be loaded,
regardless of the `-severity` given to the Perl::Mogrify constructor.

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
    # Give these policies a custom theme.  I can activate just
    # these policies by saying `perlcritic -theme larry`

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

For additional configuration examples, see the `perlcriticrc` file that is
included in this `examples` directory of this distribution.

Damian Conway's own Perl::Mogrify configuration is also included in this
distribution as `examples/perlcriticrc-conway`.

# THE POLICIES

A large number of Enforcer modules are distributed with Perl::Mogrify. They are
described briefly in the companion document [Perl::Mogrify::PolicySummary](https://metacpan.org/pod/Perl::Mogrify::PolicySummary) and
in more detail in the individual modules themselves.  Say `"perlcritic -doc
PATTERN"` to see the perldoc for all Enforcer modules that match the regex
`m/PATTERN/ixms`

There are a number of distributions of additional policies on CPAN. If
[Perl::Mogrify](https://metacpan.org/pod/Perl::Mogrify) doesn't contain a policy that you want, some one may have
already written it.  See the ["SEE ALSO"](#see-also) section below for a list of some
of these distributions.

# POLICY THEMES

Each Enforcer is defined with one or more "themes".  Themes can be used to
create arbitrary groups of Policies.  They are intended to provide an
alternative mechanism for selecting your preferred set of Policies. For
example, you may wish disable a certain subset of Policies when analyzing test
programs.  Conversely, you may wish to enable only a specific subset of
Policies when analyzing modules.

The Policies that ship with Perl::Mogrify have been broken into the following
themes.  This is just our attempt to provide some basic logical groupings.
You are free to invent new themes that suit your needs.

    THEME             DESCRIPTION
    --------------------------------------------------------------------------
    core              All policies that ship with Perl::Mogrify
    pbp               Policies that come directly from "Perl Best Practices"
    bugs              Policies that that prevent or reveal bugs
    certrec           Policies that CERT recommends
    certrule          Policies that CERT considers rules
    maintenance       Policies that affect the long-term health of the code
    cosmetic          Policies that only have a superficial effect
    complexity        Policies that specificaly relate to code complexity
    security          Policies that relate to security issues
    tests             Policies that are specific to test programs

Any Enforcer may fit into multiple themes.  Say `"perlcritic -list"` to get a
listing of all available Policies and the themes that are associated with each
one.  You can also change the theme for any Enforcer in your `.perlcriticrc`
file.  See the ["CONFIGURATION"](#configuration) section for more information about that.

Using the `-theme` option, you can create an arbitrarily complex rule that
determines which Policies will be loaded.  Precedence is the same as regular
Perl code, and you can use parentheses to enforce precedence as well.
Supported operators are:

    Operator    Alternative    Example
    -----------------------------------------------------------------
    &&          and            'pbp && core'
    ||          or             'pbp || (bugs && security)'
    !           not            'pbp && ! (portability || complexity)'

Theme names are case-insensitive.  If the `-theme` is set to an empty string,
then it evaluates as true all Policies.

# BENDING THE RULES

Perl::Mogrify takes a hard-line approach to your code: either you comply or you
don't.  In the real world, it is not always practical (nor even possible) to
fully comply with coding standards.  In such cases, it is wise to show that
you are knowingly violating the standards and that you have a Damn Good Reason
(DGR) for doing so.

To help with those situations, you can direct Perl::Mogrify to ignore certain
lines or blocks of code by using annotations:

    require 'LegacyLibaray1.pl';  ## no critic
    require 'LegacyLibrary2.pl';  ## no critic

    for my $element (@list) {

        ## no critic

        $foo = "";               #Violates 'ProhibitEmptyQuotes'
        $barf = bar() if $foo;   #Violates 'ProhibitPostfixControls'
        #Some more evil code...

        ## use critic

        #Some good code...
        do_something($_);
    }

The `"## no critic"` annotations direct Perl::Mogrify to ignore the remaining
lines of code until a `"## use critic"` annotation is found. If the `"## no
critic"` annotation is on the same line as a code statement, then only that
line of code is overlooked.  To direct perlcritic to ignore the `"## no
critic"` annotations, use the `--force` option.

A bare `"## no critic"` annotation disables all the active Policies.  If you
wish to disable only specific Policies, add a list of Enforcer names as
arguments, just as you would for the `"no strict"` or `"no warnings"`
pragmas.  For example, this would disable the `ProhibitEmptyQuotes` and
`ProhibitPostfixControls` policies until the end of the block or until the
next `"## use critic"` annotation (whichever comes first):

    ## no critic (EmptyQuotes, PostfixControls)

    # Now exempt from ValuesAndExpressions::ProhibitEmptyQuotes
    $foo = "";

    # Now exempt ControlStructures::ProhibitPostfixControls
    $barf = bar() if $foo;

    # Still subjected to ValuesAndExpression::RequireNumberSeparators
    $long_int = 10000000000;

Since the Enforcer names are matched against the `"## no critic"` arguments as
regular expressions, you can abbreviate the Enforcer names or disable an entire
family of Policies in one shot like this:

    ## no critic (NamingConventions)

    # Now exempt from NamingConventions::Capitalization
    my $camelHumpVar = 'foo';

    # Now exempt from NamingConventions::Capitalization
    sub camelHumpSub {}

The argument list must be enclosed in parentheses and must contain one or more
comma-separated barewords (e.g. don't use quotes).  The `"## no critic"`
annotations can be nested, and Policies named by an inner annotation will be
disabled along with those already disabled an outer annotation.

Some Policies like `Subroutines::ProhibitExcessComplexity` apply to an entire
block of code.  In those cases, the `"## no critic"` annotation must appear
on the line where the violation is reported.  For example:

    sub complicated_function {  ## no critic (ProhibitExcessComplexity)
        # Your code here...
    }

Policies such as `Documentation::RequirePodSections` apply to the entire
document, in which case violations are reported at line 1.

Use this feature wisely.  `"## no critic"` annotations should be used in the
smallest possible scope, or only on individual lines of code. And you should
always be as specific as possible about which Policies you want to disable
(i.e. never use a bare `"## no critic"`).  If Perl::Mogrify complains about
your code, try and find a compliant solution before resorting to this feature.

# THE [Perl::Mogrify](https://metacpan.org/pod/Perl::Mogrify) PHILOSOPHY

Coding standards are deeply personal and highly subjective.  The goal of
Perl::Mogrify is to help you write code that conforms with a set of best
practices.  Our primary goal is not to dictate what those practices are, but
rather, to implement the practices discovered by others.  Ultimately, you make
the rules -- Perl::Mogrify is merely a tool for encouraging consistency.  If
there is a policy that you think is important or that we have overlooked, we
would be very grateful for contributions, or you can simply load your own
private set of policies into Perl::Mogrify.

# EXTENDING THE CRITIC

The modular design of Perl::Mogrify is intended to facilitate the addition of
new Policies.  You'll need to have some understanding of [PPI](https://metacpan.org/pod/PPI), but most
Enforcer modules are pretty straightforward and only require about 20 lines of
code.  Please see the [Perl::Mogrify::DEVELOPER](https://metacpan.org/pod/Perl::Mogrify::DEVELOPER) file included in this
distribution for a step-by-step demonstration of how to create new Enforcer
modules.

If you develop any new Enforcer modules, feel free to send them to `<team@perlcritic.com>` and I'll be happy to consider puting them into the
Perl::Mogrify distribution.  Or if you would like to work on the Perl::Mogrify
project directly, you can fork our repository at ["/github.com/Perl-
Mogrify/Perl- Mogrify.git" in http:](https://metacpan.org/pod/http:#github.com-Perl--Mogrify-Perl--Mogrify.git).

The Perl::Mogrify team is also available for hire.  If your organization has
its own coding standards, we can create custom Policies to enforce your local
guidelines.  Or if your code base is prone to a particular defect pattern, we
can design Policies that will help you catch those costly defects **before**
they go into production. To discuss your needs with the Perl::Mogrify team,
just contact `<team@perlcritic.com>`.

# PREREQUISITES

Perl::Mogrify requires the following modules:

[B::Keywords](https://metacpan.org/pod/B::Keywords)

[Config::Tiny](https://metacpan.org/pod/Config::Tiny)

[Email::Address](https://metacpan.org/pod/Email::Address)

[Exception::Class](https://metacpan.org/pod/Exception::Class)

[File::HomeDir](https://metacpan.org/pod/File::HomeDir)

[File::Spec](https://metacpan.org/pod/File::Spec)

[File::Spec::Unix](https://metacpan.org/pod/File::Spec::Unix)

[File::Which](https://metacpan.org/pod/File::Which)

[IO::String](https://metacpan.org/pod/IO::String)

[List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

[List::Util](https://metacpan.org/pod/List::Util)

[Module::Pluggable](https://metacpan.org/pod/Module::Pluggable)

[Perl::Tidy](https://metacpan.org/pod/Perl::Tidy)

[Pod::Spell](https://metacpan.org/pod/Pod::Spell)

[PPI](https://metacpan.org/pod/PPI)

[Pod::PlainText](https://metacpan.org/pod/Pod::PlainText)

[Pod::Select](https://metacpan.org/pod/Pod::Select)

[Pod::Usage](https://metacpan.org/pod/Pod::Usage)

[Readonly](https://metacpan.org/pod/Readonly)

[Scalar::Util](https://metacpan.org/pod/Scalar::Util)

[String::Format](https://metacpan.org/pod/String::Format)

[Task::Weaken](https://metacpan.org/pod/Task::Weaken)

[Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor)

[Text::ParseWords](https://metacpan.org/pod/Text::ParseWords)

[version](https://metacpan.org/pod/version)

# CONTACTING THE DEVELOPMENT TEAM

You are encouraged to subscribe to the mailing list; send a message to
[mailto:users-subscribe@perlcritic.tigris.org](mailto:users-subscribe@perlcritic.tigris.org).  To prevent spam, you may be
required to regisgter for a user account with Tigris.org before being allowed
to post messages to the mailing list. See also the mailing list archives at
[http://perlcritic.tigris.org/servlets/SummarizeList?listName=users](http://perlcritic.tigris.org/servlets/SummarizeList?listName=users). At
least one member of the development team is usually hanging around in
[irc://irc.perl.org/#perlcritic](irc://irc.perl.org/#perlcritic) and you can follow Perl::Mogrify on Twitter,
at [https://twitter.com/perlcritic](https://twitter.com/perlcritic).

# SEE ALSO

There are a number of distributions of additional Policies available. A few
are listed here:

[Perl::Mogrify::More](https://metacpan.org/pod/Perl::Mogrify::More)

[Perl::Mogrify::Bangs](https://metacpan.org/pod/Perl::Mogrify::Bangs)

[Perl::Mogrify::Lax](https://metacpan.org/pod/Perl::Mogrify::Lax)

[Perl::Mogrify::StricterSubs](https://metacpan.org/pod/Perl::Mogrify::StricterSubs)

[Perl::Mogrify::Swift](https://metacpan.org/pod/Perl::Mogrify::Swift)

[Perl::Mogrify::Tics](https://metacpan.org/pod/Perl::Mogrify::Tics)

These distributions enable you to use Perl::Mogrify in your unit tests:

[Test::Perl::Mogrify](https://metacpan.org/pod/Test::Perl::Mogrify)

[Test::Perl::Mogrify::Progressive](https://metacpan.org/pod/Test::Perl::Mogrify::Progressive)

There is also a distribution that will install all the Perl::Mogrify related
modules known to the development team:

[Task::Perl::Mogrify](https://metacpan.org/pod/Task::Perl::Mogrify)

# BUGS

Scrutinizing Perl code is hard for humans, let alone machines.  If you find
any bugs, particularly false-positives or false-negatives from a
Perl::Mogrify::Enforcer, please submit them at ["/github.com/Perl-Mogrify
/Perl-Mogrify/issues" in https:](https://metacpan.org/pod/https:#github.com-Perl-Mogrify-Perl-Mogrify-issues).  Thanks.

# CREDITS

Adam Kennedy - For creating [PPI](https://metacpan.org/pod/PPI), the heart and soul of [Perl::Mogrify](https://metacpan.org/pod/Perl::Mogrify).

Damian Conway - For writing **Perl Best Practices**, finally :)

Chris Dolan - For contributing the best features and Enforcer modules.

Andy Lester - Wise sage and master of all-things-testing.

Elliot Shank - The self-proclaimed quality freak.

Giuseppe Maxia - For all the great ideas and positive encouragement.

and Sharon, my wife - For putting up with my all-night code sessions.

Thanks also to the Perl Foundation for providing a grant to support Chris
Dolan's project to implement twenty PBP policies.
[http://www.perlfoundation.org/april\_1\_2007\_new\_grant\_awards](http://www.perlfoundation.org/april_1_2007_new_grant_awards)

# AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

# COPYRIGHT

Copyright (c) 2005-2013 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.
