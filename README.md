# NAME

Perl::ToPerl6 - Transmogrify Perl5 code into Perl6

# SYNOPSIS

    perlmogrify source.pl

# DESCRIPTION

Perl::ToPerl6 is an extensible framework for transforming Perl5 code into Perl6.
The framework owes a great deal to Jeffrey Thalmer and Perl::Critic,
inasmuch as the source was almost completely cribbed from there. Any remaining
bugs are my fault, however.

This is meant to be extensible so that others can create their own Perl5 to
Perl6 custom transformation modules. Feel free to add them to the appropriate
Perl::ToPerl6::Transformerx namespace.

As the original Perl::Critic module still remains under the hood, you should
still be able to use the original configuration and .rc system.

The core transformations were simmply chosen by taking an existing perl5 file
and editing it until it compiled cleanly under Perl6. The author does not
guarantee that the code semantically matches the old Perl5 source, merely that
it is now compilable Perl6 code.

The documentation is still basically a s/// of the original Perl::Critic
documentation, with the exception of this README. If you're brave or foolish,
feel free to use Test::Perl::ToPerl6 to translate your code as part of your
test suite or source code control platform, but caveat emptor.

# WHAT DOES IT DO

As of the initial release, it contains transformers for:

    Basic data types (integers, floats, strings)
        Binary, Octal and Hexadecimal integer
        Floating-point trailing decimal
        Here-docs
        Interpolated values ("${x}", "$x-foo" etc.)
        Interpolated case modifiers ("\lFoo", "\Ufoo\E" etc.)
    Builtins
        'print $fh "text hee"'
    Q types
        qw(), qr(), qx()
    Conditional constructs ('if', 'elsif', 'unless', 'when')
    Looping constructs ('for', 'foreach', 'while', 'until')
        Transformation of C-style loops
    First-order operators
        'map {} @foo', 'grep !2 @a'
    Core operators ('->', '.', '<<', '>>', '!' etc.)
    Package declarations ('package My::Package;', 'package My::Package {}')
    Package usage ('use Foo::Bar')
    Pragmas ('utf8', 'warnings', 'overload' etc.)
    Dereferencing ('%{ $foo }', '%$foo' etc.)
    Hashes ('$foo{a}', "$foo{'a'}" etc.)
    Sigils ('$x', '$a[1]', '@a', '%a{a,b}' etc.)
    Special variables ('@ARGV', '@+', '%ENV' etc.)
    Special literals ('__END__', '__PACKAGE__', '__FILE__' etc.)

# CONFIGURATION

Please read Perl::Critic>s documentation for more information. Quite a bit
of this will be invalid soon as while the infrastructure it provides is
wonderful, some of the indiviual flags and data types Perl::Critic uses
aren't really appropriate for this.

# THE TRANSFORMERS

Please see the Perl::ToPerl6::Transformer:: namespace for a full listing of
the core modules that come with Perl::ToPerl6. The core modules are all
documented, albeit in a minimal sense. 'perlmogrify -doc PATTERN' might still
work and should bring up documentation for the appropriate module.

If other people do write transformer modules, I might be tempted to add
support for a L<Perl::ToPerl6::TransformerX> namespace, but we'll discuss
that issue if it ever comes up.

# TRANSFORMER THEMES

This is a completely unused feature for the moment, it may come into use once
I figure out how to properly integrate it.

# BENDING THE RULES

I don't really see a point to this at the moment unless you need to retain
a specific module or some tricky bit of syntax that fails to convert, but
the '## no mogrify' line marker may work for your needs, as it's a holdover
from this module's genesis as Perl::Critic.

# THE [Perl::ToPerl6](https://metacpan.org/pod/Perl::ToPerl6) PHILOSOPHY

For the moment, there is no facility for defining the order that transformers
are run i, so each individual module cannot rely on other transformations
being done. So far during development this hasn't been a problem, but I do
make allowances at certain points, for instance there are two separate
transformation modules for the C<for> loop, and the last one to run assumes
that nothing has been run.

There is a Perl::ToPerl6::Utils namespace where utilities for transformers
will reside, such as determining the style of a 'for' loop. This was a pain
and probably already exists on CPAN but I'm already pulling in quite a few
dependencies for this module as it is.

# EXTENDING THE MOGRIFIER

The simplest way to go about this is find a module in the list that performs a
task like what you want, copy that, and start walking its PPI tree. Each module
is presumed to act on one node of the tree at a time, in other words C<$elem>
will always be a single element of the type you're modifying. This keeps code
simple, and lets the main body collect statistics about what it's modifying.

For instance, when running it you'll get an *awful* lot of output about what
the modules are doing, complete with line and column numbers of where the
modifications are happening. This is more or less so that you can trace back
to the point of origin when a module does something you don't expect.

Your module receives the original document in C<$doc> and the element to
process in C<$elem>. If you make no modifications to the element, just return.
Otherwise, calling C<transformation()> tells the main application that your
module has changed source.

Just to keep the source tree clean and reasonably Perlish, I try to create new
tokens for whitespace and such where it's practical. Please also note that
at some points I'm forced to violate PPI encapsulation, for instance
changing brace styles or a heredoc's marker.

Something else to keep in mind as you're creating tests is that the
expression you're looking for won't always begin at the start of a
L<PPI::Statement>. As a trivial example, C<$x++> may occur at the end of
a long statement, such as C<1 if $x++>. So, when creating your test suites
be sure that at least a few of your test cases don't begin precisely at
the statement boundary.

Feel free to send me a pull request on GitHub if you've developed a module
and want it integrated.

# PREREQUISITES

Perl::ToPerl6 requires the following modules:

[B::Keywords](https://metacpan.org/pod/B::Keywords)

[Config::Tiny](https://metacpan.org/pod/Config::Tiny)

[Exception::Class](https://metacpan.org/pod/Exception::Class)

[File::HomeDir](https://metacpan.org/pod/File::HomeDir)

[File::Spec](https://metacpan.org/pod/File::Spec)

[File::Spec::Unix](https://metacpan.org/pod/File::Spec::Unix)

[File::Which](https://metacpan.org/pod/File::Which)

[IO::String](https://metacpan.org/pod/IO::String)

[List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

[List::Util](https://metacpan.org/pod/List::Util)

[Module::Pluggable](https://metacpan.org/pod/Module::Pluggable)

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

Currently the development team is just me, [mailto:drforr@pobox.com] or send
me a pull request for the appropriate module on GitHUb. I'll keep an eye out
for requests and integrate them as they come in, or within a reasonable time
frame.

You can also catch me on IRC at either [irc://irc.perl.org/#perl] or
[irc://irc.freenode.net/#perl], and follow me on Twitter at
[https://twitter.com/drforr]

# SEE ALSO

Please note this is *mostly* based on Perl::Critic code, so please see that
module if you have questions about why something was implemented. Also most
of the documentation still is from that module, and will be replaced on a
purely ad-hoc basis.

# BUGS

Feel free to submit bugs via either RT or GitHub. GitHub and personal email
gets checked more frequently, or just bounce me a note on IRC if I happen to
be active.

# CREDITS

Jeffrey Thalhammer - For creating the framework I'm shamelessly ripping off, so I don't have to create an entire plugin architecture.

Adam Kennedy - For creating [PPI](https://metacpan.org/pod/PPI), the heart and soul of [Perl::ToPerl6](https://metacpan.org/pod/Perl::ToPerl6).

Damian Conway - For writing **Perl Best Practices**, finally :)

Chris Dolan - For contributing the best features and Transformer modules.

Andy Lester - Wise sage and master of all-things-testing.

Elliot Shank - The self-proclaimed quality freak.

Giuseppe Maxia - For all the great ideas and positive encouragement.

# AUTHOR

Jeffrey Goff <drforr@pobox.com>

# AUTHOR EMERITUS

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

# COPYRIGHT

Copyright (c) 2015 Jeffrey Goff <drforr@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.
