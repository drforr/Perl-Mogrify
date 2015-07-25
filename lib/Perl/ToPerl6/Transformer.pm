package Perl::ToPerl6::Transformer;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use File::Spec ();
use String::Format qw< stringf >;

use overload ( q<""> => 'to_string', cmp => '_compare' );

use Perl::ToPerl6::Utils qw<
    :characters
    :booleans
    :severities
    :data_conversion
    interpolate
    is_integer
    policy_long_name
    policy_short_name
    severity_to_number
>;
use Perl::ToPerl6::Utils::DataConversion qw< dor >;
use Perl::ToPerl6::Utils::POD qw<
    get_module_abstract_for_module
    get_raw_module_abstract_for_module
>;
use Perl::ToPerl6::Exception::AggregateConfiguration;
use Perl::ToPerl6::Exception::Configuration;
use Perl::ToPerl6::Exception::Configuration::Option::Transformer::ExtraParameter;
use Perl::ToPerl6::Exception::Configuration::Option::Transformer::ParameterValue;
use Perl::ToPerl6::Exception::Fatal::TransformerDefinition
    qw< throw_policy_definition >;
use Perl::ToPerl6::TransformerConfig qw<>;
use Perl::ToPerl6::TransformerParameter qw<>;
use Perl::ToPerl6::Transformation qw<>;

use Exception::Class;   # this must come after "use P::C::Exception::*"

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $NO_LIMIT => 'no_limit';

#-----------------------------------------------------------------------------

my $format = "%p\n"; #Default stringy format

#-----------------------------------------------------------------------------

sub new {
    my ($class, %config) = @_;

    my $self = bless {}, $class;

    my $config_object;
    if ($config{_config_object}) {
        $config_object = $config{_config_object};
    }
    else {
        $config_object =
            Perl::ToPerl6::TransformerConfig->new(
                $self->get_short_name(),
                \%config,
            );
    }

    $self->__set_config( $config_object );

    my @parameters;
    my $parameter_metadata_available = 0;

    if ( $class->can('supported_parameters') ) {
        $parameter_metadata_available = 1;
        @parameters =
            map
                { Perl::ToPerl6::TransformerParameter->new($_) }
                $class->supported_parameters();
    }
    $self->{_parameter_metadata_available} = $parameter_metadata_available;
    $self->{_parameters} = \@parameters;

    my $errors = Perl::ToPerl6::Exception::AggregateConfiguration->new();
    foreach my $parameter ( @parameters ) {
        eval {
            $parameter->parse_and_validate_config_value( $self, $config_object );
        }
            or do {
                $errors->add_exception_or_rethrow($EVAL_ERROR);
            };

        $config_object->remove( $parameter->get_name() );
    }

    if ($parameter_metadata_available) {
        $config_object->handle_extra_parameters( $self, $errors );
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub is_safe {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub __get_parameter_name {
    my ( $self, $parameter ) = @_;

    return '_' . $parameter->get_name();
}

#-----------------------------------------------------------------------------

sub __set_parameter_value {
    my ( $self, $parameter, $value ) = @_;

    $self->{ $self->__get_parameter_name($parameter) } = $value;

    return;
}

#-----------------------------------------------------------------------------

sub __set_base_parameters {
    my ($self) = @_;

    my $config = $self->__get_config();
    my $errors = Perl::ToPerl6::Exception::AggregateConfiguration->new();

    $self->_set_maximum_transformations_per_document($errors);

    my $user_severity = $config->get_severity();
    if ( defined $user_severity ) {
        my $normalized_severity = severity_to_number( $user_severity );
        $self->set_severity( $normalized_severity );
    }

    my $user_set_themes = $config->get_set_themes();
    if ( defined $user_set_themes ) {
        my @set_themes = words_from_string( $user_set_themes );
        $self->set_themes( @set_themes );
    }

    my $user_add_themes = $config->get_add_themes();
    if ( defined $user_add_themes ) {
        my @add_themes = words_from_string( $user_add_themes );
        $self->add_themes( @add_themes );
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return;
}

#-----------------------------------------------------------------------------

sub _set_maximum_transformations_per_document {
    my ($self, $errors) = @_;

    my $config = $self->__get_config();

    if ( $config->is_maximum_transformations_per_document_unlimited() ) {
        return;
    }

    my $user_maximum_transformations =
        $config->get_maximum_transformations_per_document();

    if ( not is_integer($user_maximum_transformations) ) {
        $errors->add_exception(
            new_parameter_value_exception(
                'maximum_transformations_per_document',
                $user_maximum_transformations,
                undef,
                "does not look like an integer.\n"
            )
        );

        return;
    }
    elsif ( $user_maximum_transformations < 0 ) {
        $errors->add_exception(
            new_parameter_value_exception(
                'maximum_transformations_per_document',
                $user_maximum_transformations,
                undef,
                "is not greater than or equal to zero.\n"
            )
        );

        return;
    }

    $self->set_maximum_transformations_per_document(
        $user_maximum_transformations
    );

    return;
}

#-----------------------------------------------------------------------------

# Unparsed configuration, P::C::TransformerConfig.  Compare with get_parameters().
sub __get_config {
    my ($self) = @_;

    return $self->{_config};
}

sub __set_config {
    my ($self, $config) = @_;

    $self->{_config} = $config;

    return;
}

 #-----------------------------------------------------------------------------

sub get_long_name {
    my ($self) = @_;

    return policy_long_name(ref $self);
}

#-----------------------------------------------------------------------------

sub get_short_name {
    my ($self) = @_;

    return policy_short_name(ref $self);
}

#-----------------------------------------------------------------------------

sub is_enabled {
    my ($self) = @_;

    return $self->{_enabled};
}

#-----------------------------------------------------------------------------

sub __set_enabled {
    my ($self, $new_value) = @_;

    $self->{_enabled} = $new_value;

    return;
}

#-----------------------------------------------------------------------------

sub applies_to {
    return qw(PPI::Element);
}

#-----------------------------------------------------------------------------

sub set_maximum_transformations_per_document {
    my ($self, $maximum_transformations_per_document) = @_;

    $self->{_maximum_transformations_per_document} =
        $maximum_transformations_per_document;

    return $self;
}

#-----------------------------------------------------------------------------

sub get_maximum_transformations_per_document {
    my ($self) = @_;

    return
        exists $self->{_maximum_transformations_per_document}
            ? $self->{_maximum_transformations_per_document}
            : $self->default_maximum_transformations_per_document();
}

#-----------------------------------------------------------------------------

sub default_maximum_transformations_per_document {
    return;
}

#-----------------------------------------------------------------------------

sub set_severity {
    my ($self, $severity) = @_;
    $self->{_severity} = $severity;
    return $self;
}

#-----------------------------------------------------------------------------

sub get_severity {
    my ($self) = @_;
    return $self->{_severity} || $self->default_severity();
}

#-----------------------------------------------------------------------------

sub default_severity {
    return $SEVERITY_LOWEST;
}

#-----------------------------------------------------------------------------

sub set_themes {
    my ($self, @themes) = @_;
    $self->{_themes} = [ sort @themes ];
    return $self;
}

#-----------------------------------------------------------------------------

sub get_themes {
    my ($self) = @_;
    my @themes = defined $self->{_themes} ? @{ $self->{_themes} } : $self->default_themes();
    my @sorted_themes = sort @themes;
    return @sorted_themes;
}

#-----------------------------------------------------------------------------

sub add_themes {
    my ($self, @additional_themes) = @_;
    #By hashifying the themes, we squish duplicates
    my %merged = hashify( $self->get_themes(), @additional_themes);
    $self->{_themes} = [ keys %merged];
    return $self;
}

#-----------------------------------------------------------------------------

sub default_themes {
    return ();
}

#-----------------------------------------------------------------------------

sub get_abstract {
    my ($self) = @_;

    return get_module_abstract_for_module( ref $self );
}

#-----------------------------------------------------------------------------

sub get_raw_abstract {
    my ($self) = @_;

    return get_raw_module_abstract_for_module( ref $self );
}

#-----------------------------------------------------------------------------

sub parameter_metadata_available {
    my ($self) = @_;

    return $self->{_parameter_metadata_available};
}

#-----------------------------------------------------------------------------

sub get_parameters {
    my ($self) = @_;

    return $self->{_parameters};
}

#-----------------------------------------------------------------------------

sub transform {
    my ($self) = @_;

    return throw_policy_definition(
        $self->get_short_name() . q/ does not implement transform()./ );
}

#-----------------------------------------------------------------------------

sub transformation {
    my ( $self, $desc, $expl, $elem ) = @_;
    # HACK!! Use goto instead of an explicit call because P::C::V::new() uses caller()
    my $sev = $self->get_severity();
    @_ = ('Perl::ToPerl6::Transformation', $desc, $expl, $elem, $sev );
    goto &Perl::ToPerl6::Transformation::new;
}

#-----------------------------------------------------------------------------

sub new_parameter_value_exception {
    my ( $self, $option_name, $option_value, $source, $message_suffix ) = @_;

    return Perl::ToPerl6::Exception::Configuration::Option::Transformer::ParameterValue->new(
        policy          => $self->get_short_name(),
        option_name     => $option_name,
        option_value    => $option_value,
        source          => $source,
        message_suffix  => $message_suffix
    );
}

#-----------------------------------------------------------------------------

sub throw_parameter_value_exception {
    my ( $self, $option_name, $option_value, $source, $message_suffix ) = @_;

    $self->new_parameter_value_exception(
        $option_name, $option_value, $source, $message_suffix
    )
        ->throw();
}
## use mogrify


#-----------------------------------------------------------------------------

# Static methods.

sub set_format { return $format = $_[0] }
sub get_format { return $format         }

#-----------------------------------------------------------------------------

sub to_string {
    my ($self, @args) = @_;

    # Wrap the more expensive ones in sub{} to postpone evaluation
    my %fspec = (
         'P' => sub { $self->get_long_name() },
         'p' => sub { $self->get_short_name() },
         'a' => sub { dor($self->get_abstract(), $EMPTY) },
         'O' => sub { $self->_format_parameters(@_) },
         'U' => sub { $self->_format_lack_of_parameter_metadata(@_) },
         'S' => sub { $self->default_severity() },
         's' => sub { $self->get_severity() },
         'T' => sub { join $SPACE, $self->default_themes() },
         't' => sub { join $SPACE, $self->get_themes() },
         'V' => sub { dor( $self->default_maximum_transformations_per_document(), $NO_LIMIT ) },
         'v' => sub { dor( $self->get_maximum_transformations_per_document(), $NO_LIMIT ) },
    );
    return stringf(get_format(), %fspec);
}

sub _format_parameters {
    my ($self, $parameter_format) = @_;

    return $EMPTY if not $self->parameter_metadata_available();

    my $separator;
    if ($parameter_format) {
        $separator = $EMPTY;
    } else {
        $separator = $SPACE;
        $parameter_format = '%n';
    }

    return
        join
            $separator,
            map { $_->to_formatted_string($parameter_format) } @{ $self->get_parameters() };
}

sub _format_lack_of_parameter_metadata {
    my ($self, $message) = @_;

    return $EMPTY if $self->parameter_metadata_available();
    return interpolate($message) if $message;

    return
        'Cannot programmatically discover what parameters this policy takes.';
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

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::ToPerl6::Transformer - Base class for all Transformer modules.


=head1 DESCRIPTION

Perl::ToPerl6::Transformer is the abstract base class for all Transformer
objects.  If you're developing your own Policies, your job is to
implement and override its methods in a subclass.  To work with the
L<Perl::ToPerl6|Perl::ToPerl6> engine, your implementation must behave
as described below.  For a detailed explanation on how to make new
Transformer modules, please see the
L<Perl::ToPerl6::DEVELOPER|Perl::ToPerl6::DEVELOPER> document included
in this distribution.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<< new( ... ) >>

Don't call this.  As a Transformer author, do not implement this.  Use the
C<initialize_if_enabled()> method for your Transformer setup.  See the
L<developer|Perl::ToPerl6::DEVELOPER> documentation for more.


=item C<< initialize_if_enabled( $config ) >>

This receives an instance of
L<Perl::ToPerl6::TransformerConfig|Perl::ToPerl6::TransformerConfig> as a
parameter, and is only invoked if this Transformer is enabled by the user.
Thus, this is the preferred place for subclasses to do any
initialization.

Implementations of this method should return a boolean value
indicating whether the Transformer should continue to be enabled.  For most
subclasses, this will always be C<$TRUE>.  Policies that depend upon
external modules or other system facilities that may or may not be
available should test for the availability of these dependencies and
return C<$FALSE> if they are not.


=item C<< prepare_to_scan_document( $document ) >>

The parameter is about to be scanned by this Transformer.  Whatever this
Transformer wants to do in terms of preparation should happen here.
Returns a boolean value indicating whether the document should be
scanned at all; if this is a false value, this Transformer won't be applied
to the document.  By default, does nothing but return C<$TRUE>.


=item C< violates( $element, $document ) >

Given a L<PPI::Element|PPI::Element> and a
L<PPI::Document|PPI::Document>, returns one or more
L<Perl::ToPerl6::Transformation|Perl::ToPerl6::Transformation> objects if the
C<$element> violates this Transformer.  If there are no transformations, then it
returns an empty list.  If the Transformer encounters an exception, then it
should C<croak> with an error message and let the caller decide how to
handle it.

C<transform()> is an abstract method and it will abort if you attempt
to invoke it directly.  It is the heart of all Transformer modules, and
your subclass B<must> override this method.


=item C< transformation( $description, $explanation, $element ) >

Returns a reference to a new C<Perl::ToPerl6::Transformation> object. The
arguments are a description of the transformation (as string), an
explanation for the policy (as string) or a series of page numbers in
PBP (as an ARRAY ref), a reference to the L<PPI|PPI> element that
caused the transformation.

These are the same as the constructor to
L<Perl::ToPerl6::Transformation|Perl::ToPerl6::Transformation>, but without the
severity.  The Transformer itself knows the severity.


=item C< new_parameter_value_exception( $option_name, $option_value, $source, $message_suffix ) >

Create a
L<Perl::ToPerl6::Exception::Configuration::Option::Transformer::ParameterValue|Perl::ToPerl6::Exception::Configuration::Option::Transformer::ParameterValue>
for this Transformer.


=item C< throw_parameter_value_exception( $option_name, $option_value, $source, $message_suffix ) >

Create and throw a
L<Perl::ToPerl6::Exception::Configuration::Option::Transformer::ParameterValue|Perl::ToPerl6::Exception::Configuration::Option::Transformer::ParameterValue>.
Useful in parameter parser implementations.


=item C< get_long_name() >

Return the full package name of this policy.


=item C< get_short_name() >

Return the name of this policy without the "Perl::ToPerl6::Transformer::"
prefix.


=item C< is_enabled() >

Answer whether this policy is really active or not.  Returns a true
value if it is, a false, yet defined, value if it isn't, and an
undefined value if it hasn't yet been decided whether it will be.


=item C< applies_to() >

Returns a list of the names of PPI classes that this Transformer cares
about.  By default, the result is C<PPI::Element>.  Overriding this
method in Transformer subclasses should lead to significant performance
increases.


=item C< default_maximum_transformations_per_document() >

Returns the default maximum number of transformations for this policy to
report per document.  By default, this not defined, but subclasses may
override this.


=item C< get_maximum_transformations_per_document() >

Returns the maximum number of transformations this policy will report for a
single document.  If this is not defined, then there is no limit.  If
L</set_maximum_transformations_per_document()> has not been invoked, then
L</default_maximum_transformations_per_document()> is returned.


=item C< set_maximum_transformations_per_document() >

Specify the maximum transformations that this policy should report for a
document.


=item C< default_severity() >

Returns the default severity for violating this Transformer.  See the
C<$SEVERITY> constants in L<Perl::ToPerl6::Utils|Perl::ToPerl6::Utils>
for an enumeration of possible severity values.  By default, this
method returns C<$SEVERITY_LOWEST>.  Authors of Perl::ToPerl6::Transformer
subclasses should override this method to return a value that they
feel is appropriate for their Transformer.  In general, Polices that are
widely accepted or tend to prevent bugs should have a higher severity
than those that are more subjective or cosmetic in nature.


=item C< get_severity() >

Returns the severity of violating this Transformer.  If the severity has
not been explicitly defined by calling C<set_severity>, then the
C<default_severity> is returned.  See the C<$SEVERITY> constants in
L<Perl::ToPerl6::Utils|Perl::ToPerl6::Utils> for an enumeration of
possible severity values.


=item C< set_severity( $N ) >

Sets the severity for violating this Transformer.  Clients of
Perl::ToPerl6::Transformer objects can call this method to assign a
different severity to the Transformer if they don't agree with the
C<default_severity>.  See the C<$SEVERITY> constants in
L<Perl::ToPerl6::Utils|Perl::ToPerl6::Utils> for an enumeration of
possible values.


=item C< default_themes() >

Returns a sorted list of the default themes associated with this
Transformer.  The default method returns an empty list.  Transformer authors
should override this method to return a list of themes that are
appropriate for their policy.


=item C< get_themes() >

Returns a sorted list of the themes associated with this Transformer.  If
you haven't added themes or set the themes explicitly, this method
just returns the default themes.


=item C< set_themes( @THEME_LIST ) >

Sets the themes associated with this Transformer.  Any existing themes are
overwritten.  Duplicate themes will be removed.


=item C< add_themes( @THEME_LIST ) >

Appends additional themes to this Transformer.  Any existing themes are
preserved.  Duplicate themes will be removed.


=item C< get_abstract() >

Retrieve the abstract for this policy (the part of the NAME section of
the POD after the module name), if it is available.


=item C< get_raw_abstract() >

Retrieve the abstract for this policy (the part of the NAME section of
the POD after the module name), if it is available, in the unparsed
form.


=item C< parameter_metadata_available() >

Returns whether information about the parameters is available.


=item C< get_parameters() >

Returns a reference to an array containing instances of
L<Perl::ToPerl6::TransformerParameter|Perl::ToPerl6::TransformerParameter>.

Note that this will return an empty list if the parameters for this
policy are unknown.  In order to differentiate between this
circumstance and the one where this policy does not take any
parameters, it is necessary to call C<parameter_metadata_available()>.


=item C<set_format( $format )>

Class method.  Sets the format for all Transformer objects when they are
evaluated in string context.  The default is C<"%p\n">.  See
L<"OVERLOADS"> for formatting options.


=item C<get_format()>

Class method. Returns the current format for all Transformer objects when
they are evaluated in string context.


=item C<to_string()>

Returns a string representation of the policy.  The content of the
string depends on the current value returned by C<get_format()>.
See L<"OVERLOADS"> for the details.


=item C<is_safe()>

Answer whether this Transformer can be used to analyze untrusted code, i.e. the
Transformer doesn't have any potential side effects.

This method returns a true value by default.

An "unsafe" policy might attempt to compile the code, which, if you have
C<BEGIN> or C<CHECK> blocks that affect files or connect to databases, is not
a safe thing to do.  If you are writing a such a Transformer, then you should
override this method to return false.

By default L<Perl::ToPerl6|Perl::ToPerl6> will not run unsafe transformers.



=back


=head1 DOCUMENTATION

When your Transformer module first C<use>s
L<Perl::ToPerl6::Transformation|Perl::ToPerl6::Transformation>, it will try and
extract the DESCRIPTION section of your Transformer module's POD.  This
information is displayed by Perl::ToPerl6 if the verbosity level is set
accordingly.  Therefore, please include a DESCRIPTION section in the
POD for any Transformer modules that you author.  Thanks.


=head1 OVERLOADS

Perl::ToPerl6::Transformation overloads the C<""> operator to produce neat
little messages when evaluated in string context.

Formats are a combination of literal and escape characters similar to
the way C<sprintf> works.  If you want to know the specific formatting
capabilities, look at L<String::Format|String::Format>. Valid escape
characters are:


=over

=item C<%P>

Name of the Transformer module.


=item C<%p>

Name of the Transformer without the C<Perl::ToPerl6::Transformer::> prefix.


=item C<%a>

The policy abstract.


=item C<%O>

List of supported policy parameters.  Takes an option of a format
string for L<Perl::ToPerl6::TransformerParameter/"to_formatted_string">.
For example, this can be used like C<%{%n - %d\n}O> to get a list of
parameter names followed by their descriptions.


=item C<%U>

A message stating that the parameters for the policy are unknown if
C<parameter_metadata_available()> returns false.  Takes an option of
what the message should be, which defaults to "Cannot programmatically
discover what parameters this policy takes.".  The value of this
option is interpolated in order to expand the standard escape
sequences (C<\n>, C<\t>, etc.).


=item C<%S>

The default severity level of the policy.


=item C<%s>

The current severity level of the policy.


=item C<%T>

The default themes for the policy.


=item C<%t>

The current themes for the policy.


=item C<%V>

The default maximum number of transformations per document of the policy.


=item C<%v>

The current maximum number of transformations per document of the policy.


=back


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
