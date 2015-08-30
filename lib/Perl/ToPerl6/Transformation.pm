package Perl::ToPerl6::Transformation;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use File::Basename qw< basename >;
use IO::String qw< >;
use Pod::PlainText qw< >;
use Scalar::Util qw< blessed >;
use String::Format qw< stringf >;

use overload ( q{""} => 'to_string', cmp => '_compare' );

use Perl::ToPerl6::Utils qw< :characters :internal_lookup >;
use Perl::ToPerl6::Utils::POD qw<
    get_pod_section_for_module
    trim_pod_section
>;
use Perl::ToPerl6::Exception::Fatal::Internal qw< throw_internal >;

Readonly::Scalar my $LOCATION_LINE_NUMBER               => 0;
Readonly::Scalar my $LOCATION_COLUMN_NUMBER             => 1;
Readonly::Scalar my $LOCATION_VISUAL_COLUMN_NUMBER      => 2;
Readonly::Scalar my $LOCATION_LOGICAL_LINE_NUMBER       => 3;
Readonly::Scalar my $LOCATION_LOGICAL_FILENAME          => 4;


# Class variables...
my $format = "%m at line %l, column %c. %e.\n"; # Default stringy format
my %diagnostics = ();  # Cache of diagnostic messages

#-----------------------------------------------------------------------------

Readonly::Scalar my $CONSTRUCTOR_ARG_COUNT => 5;

sub new {
    my ( $class, $desc, $expl, $elem, $sev ) = @_;

    # Check arguments to help out developers who might
    # be creating new Perl::ToPerl6::Transformer modules.

    if ( @_ != $CONSTRUCTOR_ARG_COUNT ) {
        throw_internal 'Wrong number of args to Transformation->new()';
    }

    if ( eval { $elem->isa( 'Perl::ToPerl6::Document' ) } ) {
        # break the facade, return the real PPI::Document
        $elem = $elem->ppi_document();
    }

    if ( not eval { $elem->isa( 'PPI::Element' ) } ) {
        throw_internal '3rd arg to Transformation->new() must be a PPI::Element';
    }

    # Strip punctuation.  These are controlled by the user via the
    # formats.  He/She can use whatever makes sense to them.
    ($desc, $expl) = _chomp_periods($desc, $expl);

    # Create object
    my $self = bless {}, $class;
    $self->{_description} = $desc;
    $self->{_explanation} = $expl;
    $self->{_necessity}    = $sev;
    $self->{_transformer}      = caller;

    # PPI eviscerates the Elements in a Document when the Document gets
    # DESTROY()ed, and thus they aren't useful after it is gone.  So we have
    # to preemptively grab everything we could possibly want.
    $self->{_element_class} = blessed $elem;

    my $top = $elem->top();
    $self->{_filename} = $top->can('filename') ? $top->filename() : undef;
    $self->{_source}   = _line_containing_transformation( $elem );
    $self->{_location} =
        $elem->location() || [ 0, 0, 0, 0, $self->filename() ];

    return $self;
}

#-----------------------------------------------------------------------------

sub set_format { return $format = verbosity_to_format( $_[0] ); }
sub get_format { return $format;         }

#-----------------------------------------------------------------------------

sub sort_by_location {

    ref $_[0] || shift;              # Can call as object or class method
    return scalar @_ if ! wantarray; # In case we are called in scalar context

    ## TODO: What if $a and $b are not Transformation objects?
    return
        map {$_->[0]}
            sort { ($a->[1] <=> $b->[1]) || ($a->[2] <=> $b->[2]) }
                map {[$_, $_->location->[0] || 0, $_->location->[1] || 0]}
                    @_;
}

#-----------------------------------------------------------------------------

sub sort_by_necessity {

    ref $_[0] || shift;              # Can call as object or class method
    return scalar @_ if ! wantarray; # In case we are called in scalar context

    ## TODO: What if $a and $b are not Transformation objects?
    return
        map {$_->[0]}
            sort { $a->[1] <=> $b->[1] }
                map {[$_, $_->necessity() || 0]}
                    @_;
}

#-----------------------------------------------------------------------------

sub location {
    my $self = shift;

    return $self->{_location};
}

#-----------------------------------------------------------------------------

sub line_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_LINE_NUMBER];
}

#-----------------------------------------------------------------------------

sub logical_line_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_LOGICAL_LINE_NUMBER];
}

#-----------------------------------------------------------------------------

sub column_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_COLUMN_NUMBER];
}

#-----------------------------------------------------------------------------

sub visual_column_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_VISUAL_COLUMN_NUMBER];
}

#-----------------------------------------------------------------------------

sub diagnostics {
    my ($self) = @_;
    my $transformer = $self->transformer();

    if ( not $diagnostics{$transformer} ) {
        eval {
            my $module_name = ref $transformer || $transformer;
            $diagnostics{$transformer} =
                trim_pod_section(
                    get_pod_section_for_module( $module_name, 'DESCRIPTION' )
                );
        };
        $diagnostics{$transformer} ||= "    No diagnostics available\n";
    }
    return $diagnostics{$transformer};
}

#-----------------------------------------------------------------------------

sub description {
    my $self = shift;
    return $self->{_description};
}

#-----------------------------------------------------------------------------

sub explanation {
    my $self = shift;
    my $expl = $self->{_explanation};
    if ( !$expl ) {
       $expl = '(no explanation)';
    }
    if ( ref $expl eq 'ARRAY' ) {
        my $page = @{$expl} > 1 ? 'pages' : 'page';
        $page .= $SPACE . join $COMMA, @{$expl};
        $expl = "See $page of PBP";
    }
    return $expl;
}

#-----------------------------------------------------------------------------

sub necessity {
    my $self = shift;
    return $self->{_necessity};
}

#-----------------------------------------------------------------------------

sub transformer {
    my $self = shift;
    return $self->{_transformer};
}

#-----------------------------------------------------------------------------

sub filename {
    my $self = shift;
    return $self->{_filename};
}

#-----------------------------------------------------------------------------

sub logical_filename {
    my ($self) = @_;

    return $self->location()->[$LOCATION_LOGICAL_FILENAME];
}

#-----------------------------------------------------------------------------

sub source {
    my $self = shift;
    return $self->{_source};
}

#-----------------------------------------------------------------------------

sub element_class {
    my ($self) = @_;

    return $self->{_element_class};
}

#-----------------------------------------------------------------------------

sub to_string {
    my $self = shift;

    my $long_transformer = $self->transformer();
    (my $short_transformer = $long_transformer) =~ s/ \A Perl::ToPerl6::Transformer:: //xms;

    # Wrap the more expensive ones in sub{} to postpone evaluation
    my %fspec = (
         'f' => sub { $self->logical_filename()             },
         'F' => sub { basename( $self->logical_filename() ) },
         'g' => sub { $self->filename()                     },
         'G' => sub { basename( $self->filename() )         },
         'l' => sub { $self->logical_line_number()          },
         'L' => sub { $self->line_number()                  },
         'c' => sub { $self->visual_column_number()         },
         'C' => sub { $self->element_class()                },
         'm' => $self->description(),
         'e' => $self->explanation(),
         's' => $self->necessity(),
         'd' => sub { $self->diagnostics()                  },
         'r' => sub { $self->source()                       },
         'P' => $long_transformer,
         'p' => $short_transformer,
    );
    return stringf($format, %fspec);
}

#-----------------------------------------------------------------------------
# Apparently, some perls do not implicitly stringify overloading
# objects before doing a comparison.  This causes a couple of our
# sorting tests to fail.  To work around this, we overload C<cmp> to
# do it explicitly.
#
# 20060503 - More information:  This problem has been traced to
# Test::Simple versions <= 0.60, not perl itself.  Upgrading to
# Test::Simple v0.62 will fix the problem.  But rather than forcing
# everyone to upgrade, I have decided to leave this workaround in
# place.

sub _compare { return "$_[0]" cmp "$_[1]" }

#-----------------------------------------------------------------------------

sub _line_containing_transformation {
    my ( $elem ) = @_;

    my $stmnt = $elem->statement() || $elem;
    my $code_string = $stmnt->content() || $EMPTY;

    # Split into individual lines
    my @lines = split qr{ \n\s* }xms, $code_string;

    # Take the line containing the element that is in transformation
    my $inx = ( $elem->line_number() || 0 ) -
        ( $stmnt->line_number() || 0 );
    $inx > @lines and return $EMPTY;
    return $lines[$inx];
}

#-----------------------------------------------------------------------------

sub _chomp_periods {
    my @args = @_;

    for (@args) {
        next if not defined or ref;
        s{ [.]+ \z }{}xms
    }

    return @args;
}

#-----------------------------------------------------------------------------

1;

#-----------------------------------------------------------------------------

__END__

=head1 NAME

Perl::ToPerl6::Transformation - A transformation of a Transformer found in some source code.


=head1 SYNOPSIS

  use PPI;
  use Perl::ToPerl6::Transformation;

  my $elem = $doc->child(0);      # $doc is a PPI::Document object
  my $desc = 'Offending code';    # Describe the transformation
  my $expl = [1,45,67];           # Page numbers from PBP
  my $sev  = 5;                   # Necessity level of this transformation

  my $vio  = Perl::ToPerl6::Transformation->new($desc, $expl, $node, $sev);


=head1 DESCRIPTION

Perl::ToPerl6::Transformation is the generic representation of an individual
Transformer transformation.  Its primary purpose is to provide an abstraction
layer so that clients of L<Perl::ToPerl6|Perl::ToPerl6> don't have to
know anything about L<PPI|PPI>.  The C<transformations> method of all
L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer> subclasses must return a
list of these Perl::ToPerl6::Transformation objects.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CONSTRUCTOR

=over

=item C<new( $description, $explanation, $element, $necessity )>

Returns a reference to a new C<Perl::ToPerl6::Transformation> object. The
arguments are a description of the transformation (as string), an
explanation for the transformer (as string) or a series of page numbers in
PBP (as an ARRAY ref), a reference to the L<PPI|PPI> element that
caused the transformation, and the necessity of the transformation (as an
integer).


=back


=head1 METHODS

=over

=item C<description()>

Returns a brief description of the specific transformation.  In other
words, this value may change on a per transformation basis.


=item C<explanation()>

Returns an explanation of the transformer as a string or as reference to an
array of page numbers in PBP.  This value will generally not change
based upon the specific code violating the transformer.


=item C<location()>

Don't use this method.  Use the C<line_number()>,
C<logical_line_number()>, C<column_number()>,
C<visual_column_number()>, and C<logical_filename()> methods instead.

Returns a five-element array reference containing the line and real &
virtual column and logical numbers and logical file name where this
Transformation occurred, as in L<PPI::Element|PPI::Element>.


=item C<line_number()>

Returns the physical line number that the transformation was found on.


=item C<logical_line_number()>

Returns the logical line number that the transformation was found on.  This
can differ from the physical line number when there were C<#line>
directives in the code.


=item C<column_number()>

Returns the physical column that the transformation was found at.  This
means that hard tab characters count as a single character.


=item C<visual_column_number()>

Returns the column that the transformation was found at, as it would appear
if hard tab characters were expanded, based upon the value of
L<PPI::Document/"tab_width [ $width ]">.


=item C<filename()>

Returns the path to the file where this Transformation occurred.  In some
cases, the path may be undefined because the source code was not read
directly from a file.


=item C<logical_filename()>

Returns the logical path to the file where the Transformation occurred.
This can differ from C<filename()> when there was a C<#line> directive
in the code.


=item C<necessity()>

Returns the necessity of this Transformation as an integer ranging from 1 to
5, where 5 is the "most" severe.


=item C<sort_by_necessity( @transformation_objects )>

If you need to sort Transformations by necessity, use this handy routine:

    @sorted = Perl::ToPerl6::Transformation::sort_by_necessity(@transformations);


=item C<sort_by_location( @transformation_objects )>

If you need to sort Transformations by location, use this handy routine:

    @sorted = Perl::ToPerl6::Transformation::sort_by_location(@transformations);


=item C<diagnostics()>

Returns a formatted string containing a full discussion of the
motivation for and details of the Transformer module that created this
Transformation.  This information is automatically extracted from the
C<DESCRIPTION> section of the Transformer module's POD.


=item C<transformer()>

Returns the name of the L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer>
that created this Transformation.


=item C<source()>

Returns the string of source code that caused this exception.  If the
code spans multiple lines (e.g. multi-line statements, subroutines or
other blocks), then only the line containing the transformation will be
returned.


=item C<element_class()>

Returns the L<PPI::Element|PPI::Element> subclass of the code that caused this
exception.


=item C<set_format( $format )>

Class method.  Sets the format for all Transformation objects when they are
evaluated in string context.  The default is C<'%d at line %l, column
%c. %e'>.  See L<"OVERLOADS"> for formatting options.


=item C<get_format()>

Class method. Returns the current format for all Transformation objects
when they are evaluated in string context.


=item C<to_string()>

Returns a string representation of this transformation.  The content of the
string depends on the current value of the C<$format> package
variable.  See L<"OVERLOADS"> for the details.


=back


=head1 OVERLOADS

Perl::ToPerl6::Transformation overloads the C<""> operator to produce neat
little messages when evaluated in string context.

Formats are a combination of literal and escape characters similar to
the way C<sprintf> works.  If you want to know the specific formatting
capabilities, look at L<String::Format|String::Format>. Valid escape
characters are:

    Escape    Meaning
    -------   ----------------------------------------------------------------
    %c        Column number where the transformation occurred
    %d        Full diagnostic discussion of the transformation (DESCRIPTION in POD)
    %e        Explanation of transformation or page numbers in PBP
    %F        Just the name of the logical file where the transformation occurred.
    %f        Path to the logical file where the transformation occurred.
    %G        Just the name of the physical file where the transformation occurred.
    %g        Path to the physical file where the transformation occurred.
    %l        Logical line number where the transformation occurred
    %L        Physical line number where the transformation occurred
    %m        Brief description of the transformation
    %P        Full name of the Transformer module that created the transformation
    %p        Name of the Transformer without the Perl::ToPerl6::Transformer:: prefix
    %r        The string of source code that caused the transformation
    %C        The class of the PPI::Element that caused the transformation
    %s        The necessity level of the transformation

Explanation of the C<%F>, C<%f>, C<%G>, C<%G>, C<%l>, and C<%L> formats:
Using C<#line> directives, you can affect what perl thinks the current line
number and file name are; see L<perlsyn/Plain Old Comments (Not!)> for
the details.  Under normal circumstances, the values of C<%F>, C<%f>, and
C<%l> will match the values of C<%G>, C<%g>, and C<%L>, respectively.  In the
presence of a C<#line> directive, the values of C<%F>, C<%f>, and C<%l> will
change to take that directive into account.  The values of C<%G>, C<%g>, and
C<%L> are unaffected by those directives.

Here are some examples:

    Perl::ToPerl6::Transformation::set_format("%m at line %l, column %c.\n");
    # looks like "Mixed case variable name at line 6, column 23."

    Perl::ToPerl6::Transformation::set_format("%m near '%r'\n");
    # looks like "Mixed case variable name near 'my $theGreatAnswer = 42;'"

    Perl::ToPerl6::Transformation::set_format("%l:%c:%p\n");
    # looks like "6:23:NamingConventions::Capitalization"

    Perl::ToPerl6::Transformation::set_format("%m at line %l. %e. \n%d\n");
    # looks like "Mixed case variable name at line 6.  See page 44 of PBP.
      Conway's recommended naming convention is to use lower-case words
      separated by underscores.  Well-recognized acronyms can be in ALL
      CAPS, but must be separated by underscores from other parts of the
      name."


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
