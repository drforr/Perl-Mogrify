#!perl

use 5.006001;
use strict;
use warnings;

use Test::More (tests => 32);
use Perl::ToPerl6::TransformerFactory (-test => 1);

# common P::C testing tools
use Perl::ToPerl6::TestUtils qw(transform);

#-----------------------------------------------------------------------------

Perl::ToPerl6::TestUtils::block_perlmogrifyrc();

# Configure ToPerl6 not to load certain transformers.  This
# just makes it a little easier to create test cases
my $profile = {
    '-Arrays::AddWhitespace'             => {},
    '-BasicTypes::Strings::FormatRegexp' => {},
    '-Builtins::RewritePrint'            => {},
    '-CompoundStatements::AddWhitespace' => {},
    '-Operators::FormatOperators'        => {},
    '-Variables::ReplaceUndef'           => {},
};

my $code = undef;

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

require 'some_library.pl';  ## no mogrify
print $crap if $condition;  ## no mogrify

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'}
    ),
    0,
    'inline no-mogrify disables transformations'
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$foo = $bar;

## no mogrify

require 'some_library.pl';
print $crap if $condition;

## use mogrify

$baz = $nuts;
1;
END_PERL

SKIP: {
    skip "XXX Must fix this properly", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    0,
    'region no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no mogrify
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    1,
    'scoped no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

{
  ## no mogrify
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    1,
    'scoped no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

## use mogrify
my $noisy = '!';

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    1,
    'region no-mogrify across a scope',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no mogrify
  $long_int = 12345678;
  $oct_num  = 033;
  ## use mogrify
}

my $noisy = '!';
my $empty = '';

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    2,
    'scoped region no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    0,
    'unterminated no-mogrify across a scope',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no mogrify
$oct_num  = 033;       ## no mogrify
my $noisy = '!';       ## no mogrify
my $empty = '';        ## no mogrify
my $empty = '';        ## use mogrify

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    1,
    'inline use-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no mogrify
$oct_num  = 033;       ## no mogrify
my $noisy = '!';       ## no mogrify
my $empty = '';        ## no mogrify

$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    5,
    q<inline no-mogrify doesn't block later transformations>,
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no mogrify
$oct_num  = 033;       ## no mogrify
my $noisy = '!';       ## no mogrify
my $empty = '';        ## no mogrify

## no mogrify
$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {
            -profile  => $profile,
            -necessity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    9,
    'force option',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no mogrify
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!'; ## no mogrify
my $empty = '';  ## no mogrify

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {
            -profile  => $profile,
            -necessity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    4,
    'force option',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no mogrify
  $long_int = 12345678;
  $oct_num  = 033;
}

## no mogrify
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {
            -profile  => $profile,
            -necessity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    5,
    'force option',
);
}

#-----------------------------------------------------------------------------
# Check that '## no mogrify' on the top of a block doesn't extend
# to all code within the block.  See RT bug #15295

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for ($i;$i++;$i<$j) { ## no mogrify
    my $long_int = 12345678;
    my $oct_num  = 033;
}

unless ( $condition1
         && $condition2 ) { ## no mogrify
    my $noisy = '!';
    my $empty = '';
}

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'},
    ),
    4,
    'RT bug 15295',
);
}

#-----------------------------------------------------------------------------
# Check that '## no mogrify' on the top of a block doesn't extend
# to all code within the block.  See RT bug #15295

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for ($i; $i++; $i<$j) { ## no mogrify
    my $long_int = 12345678;
    my $oct_num  = 033;
}

#Between blocks now
$Global::Variable = "foo";  #Package var; double-quotes

unless ( $condition1
         && $condition2 ) { ## no mogrify
    my $noisy = '!';
    my $empty = '';
}

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    6,
    'RT bug 15295',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

sub grep {  ## no mogrify;
    return $foo;
}

sub grep { return $foo; } ## no mogrify
1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'},
    ),
    0,
    'no-mogrify on sub name',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

sub grep {  ## no mogrify;
   return undef; #Should find this!
}

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity =>1, -theme => 'core'}
    ),
    1,
    'no-mogrify on sub name',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (NoisyQuotes)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    2,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (ValuesAndExpressions)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    1,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (Noisy, Empty)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    1,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (NOISY, EMPTY, EVAL)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    0,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (Noisy, Empty, Eval)
my $noisy = '!';
my $empty = '';
eval $string;

## use mogrify
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    3,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (ToPerl6::Transformer)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    0,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (Foo::Bar, Baz, Boom)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    3,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no mogrify (Noisy)
my $noisy = '!';     #Should not find this
my $empty = '';      #Should find this

sub foo {

   ## no mogrify (Empty)
   my $nosiy = '!';  #Should not find this
   my $empty = '';   #Should not find this
   ## use mogrify;

   return 1;
}

my $nosiy = '!';  #Should not find this
my $empty = '';   #Should find this

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'}
    ),
    2,
    'per-transformer no-mogrify',
);
}

#-----------------------------------------------------------------------------
$code = <<'END_PERL';
package FOO;

use strict;
use warnings;
our $VERSION = 1.0;

# with parentheses
my $noisy = '!';           ##no mogrify (NoisyQuotes)
barf() unless $$ eq '';    ##no mogrify (Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no mogrify (Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##no mogrify (Postfix Empty Punctuation)

# qw() style
my $noisy = '!';           ##no mogrify qw(NoisyQuotes);
barf() unless $$ eq '';    ##no mogrify qw(Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no mogrify qw(Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##no mogrify qw(Postfix Empty Punctuation)

# with quotes
my $noisy = '!';           ##no mogrify 'NoisyQuotes';
barf() unless $$ eq '';    ##no mogrify 'Postfix,Empty,Punctuation';
barf() unless $$ eq '';    ##no mogrify 'Postfix , Empty , Punctuation';
barf() unless $$ eq '';    ##no mogrify 'Postfix Empty Punctuation';

# with double quotes
my $noisy = '!';           ##no mogrify "NoisyQuotes";
barf() unless $$ eq '';    ##no mogrify "Postfix,Empty,Punctuation";
barf() unless $$ eq '';    ##no mogrify "Postfix , Empty , Punctuation";
barf() unless $$ eq '';    ##no mogrify "Postfix Empty Punctuation";

# with spacing variations
my $noisy = '!';           ##no mogrify (NoisyQuotes)
barf() unless $$ eq '';    ##  no   mogrify   (Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no mogrify(Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##   no mogrify(Postfix Empty Punctuation)

1;

END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile => $profile, -necessity => 1, -theme => 'core'},
    ),
    0,
    'no mogrify: syntaxes',
);
}

#-----------------------------------------------------------------------------
# Most transformers apply to a particular type of PPI::Element and usually
# only return one Transformation at a time.  But the next three cases
# involve transformers that apply to the whole document and can return
# multiple transformations at a time.  These tests make sure that the 'no
# mogrify' pragmas are effective with those Transformers
#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;

#Code before 'use strict'
my $foo = 'baz';  ## no mogrify
my $bar = 42;     # Should find this

use strict;
use warnings;
our $VERSION = 1.0;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 5, -theme => 'core'},
    ),
    1,
    'no mogrify & RequireUseStrict',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;

#Code before 'use warnings'
my $foo = 'baz';  ## no mogrify
my $bar = 42;  # Should find this

use warnings;
our $VERSION = 1.0;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 4, -theme => 'core'},
    ),
    1,
    'no mogrify & RequireUseWarnings',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use strict;      ##no mogrify
use warnings;    #should find this
my $bar = 42;    #this one will be squelched

package FOO;

our $VERSION = 1.0;

1;
END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 4, -theme => 'core'},
    ),
    1,
    'no mogrify & RequireExplicitPackage',
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl -w ## no mogrify

package Foo;
use strict;
use warnings;
our $VERSION = 1;

my $noisy = '!'; # should find this

END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'},
    ),
    1,
    'no-mogrify on shebang line'
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#line 1
## no mogrify;

=pod

=head1 SOME POD HERE

This code has several POD-related transformations at line 1.  The "## no mogrify"
marker is on the second physical line.  However, the "#line" directive should
cause it to treat it as if it actually were on the first physical line.  Thus,
the transformations should be supressed.

=cut

END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'},
    ),
    0,
    'no-mogrify where logical line == 1, but physical line != 1'
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#line 7
## no mogrify;

=pod

=head1 SOME POD HERE

This code has several POD-related transformations at line 1.  The "## no mogrify"
marker is on the second physical line, and the "#line" directive should cause
it to treat it as if it actually were on the 7th physical line.  Thus, the
transformations should NOT be supressed.

=cut

END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'},
    ),
    2,
    'no-mogrify at logical line != 1, and physical line != 1'
);
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#line 1
#!perl ### no mogrify;

package Foo;
use strict;
use warnings;
our $VERSION = 1;

# In this case, the "## no mogrify" marker is on the first logical line, which
# is also the shebang line.

1;

END_PERL

SKIP: {
    skip "XXX Must fix this later", 1;
is(
    transform(
        \$code,
        {-profile  => $profile, -necessity => 1, -theme => 'core'},
    ),
    0,
    'no-mogrify on shebang line, where physical line != 1, but logical line == 1'
);
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/03_pragmas.t_without_optional_dependencies.t
1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
