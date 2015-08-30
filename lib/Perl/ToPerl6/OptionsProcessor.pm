package Perl::ToPerl6::OptionsProcessor;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::ToPerl6::Exception::AggregateConfiguration;
use Perl::ToPerl6::Exception::Configuration::Option::Global::ExtraParameter;
use Perl::ToPerl6::Utils qw<
    :booleans :characters :severities :data_conversion $DEFAULT_VERBOSITY
>;
use Perl::ToPerl6::Utils::Constants qw<
    $PROFILE_STRICTNESS_DEFAULT
    :color_necessity
    >;
use Perl::ToPerl6::Utils::DataConversion qw< dor >;

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {
    my ( $self, %args ) = @_;

    # Multi-value defaults
    my $exclude = dor(delete $args{exclude}, $EMPTY);
    $self->{_exclude}    = [ words_from_string( $exclude ) ];

    my $include = dor(delete $args{include}, $EMPTY);
    $self->{_include}    = [ words_from_string( $include ) ];

    my $program_extensions = dor(delete $args{'program-extensions'}, $EMPTY);
    $self->{_program_extensions} = [ words_from_string( $program_extensions) ];

    # Single-value defaults
    $self->{_force}           = dor(delete $args{force},              $FALSE);
    $self->{_in_place}        = dor(delete $args{'in-place'},         $FALSE);
    $self->{_only}            = dor(delete $args{only},               $FALSE);
    $self->{_profile_strictness} =
        dor(delete $args{'profile-strictness'}, $PROFILE_STRICTNESS_DEFAULT);
    $self->{_single_transformer}   = dor(delete $args{'single-transformer'},    $EMPTY);
    $self->{_necessity}        = dor(delete $args{necessity},           $NECESSITY_HIGHEST);
    $self->{_detail}           = dor(delete $args{detail},           $NECESSITY_LOWEST + 1);
    $self->{_theme}           = dor(delete $args{theme},              $EMPTY);
    $self->{_top}             = dor(delete $args{top},                $FALSE);
    $self->{_verbose}         = dor(delete $args{verbose},            $DEFAULT_VERBOSITY);
    $self->{_pager}           = dor(delete $args{pager},              $EMPTY);

    $self->{_color_necessity_highest} = dor(
        delete $args{'color-necessity-highest'},
        delete $args{'colour-necessity-highest'},
        delete $args{'color-necessity-5'},
        delete $args{'colour-necessity-5'},
        $PROFILE_COLOR_NECESSITY_HIGHEST_DEFAULT,
    );
    $self->{_color_necessity_high} = dor(
        delete $args{'color-necessity-high'},
        delete $args{'colour-necessity-high'},
        delete $args{'color-necessity-4'},
        delete $args{'colour-necessity-4'},
        $PROFILE_COLOR_NECESSITY_HIGH_DEFAULT,
    );
    $self->{_color_necessity_medium} = dor(
        delete $args{'color-necessity-medium'},
        delete $args{'colour-necessity-medium'},
        delete $args{'color-necessity-3'},
        delete $args{'colour-necessity-3'},
        $PROFILE_COLOR_NECESSITY_MEDIUM_DEFAULT,
    );
    $self->{_color_necessity_low} = dor(
        delete $args{'color-necessity-low'},
        delete $args{'colour-necessity-low'},
        delete $args{'color-necessity-2'},
        delete $args{'colour-necessity-2'},
        $PROFILE_COLOR_NECESSITY_LOW_DEFAULT,
    );
    $self->{_color_necessity_lowest} = dor(
        delete $args{'color-necessity-lowest'},
        delete $args{'colour-necessity-lowest'},
        delete $args{'color-necessity-1'},
        delete $args{'colour-necessity-1'},
        $PROFILE_COLOR_NECESSITY_LOWEST_DEFAULT,
    );

    # If we're using a pager or not outputing to a tty don't use colors.
    # Can't use IO::Interactive here because we /don't/ want to check STDIN.
    my $default_color = ($self->pager() or not -t *STDOUT) ? $FALSE : $TRUE;
    $self->{_color} = dor(delete $args{color}, delete $args{colour}, $default_color);

    # If there's anything left, complain.
    _check_for_extra_options(%args);

    return $self;
}

#-----------------------------------------------------------------------------

sub _check_for_extra_options {
    my %args = @_;

    if ( my @remaining = sort keys %args ){
        my $errors = Perl::ToPerl6::Exception::AggregateConfiguration->new();

        foreach my $option_name (@remaining) {
            $errors->add_exception(
                Perl::ToPerl6::Exception::Configuration::Option::Global::ExtraParameter->new(
                    option_name     => $option_name,
                )
            )
        }

        $errors->rethrow();
    }

    return;
}

#-----------------------------------------------------------------------------
# Public ACCESSOR methods

sub necessity {
    my ($self) = @_;
    return $self->{_necessity};
}

#-----------------------------------------------------------------------------

sub theme {
    my ($self) = @_;
    return $self->{_theme};
}

#-----------------------------------------------------------------------------

sub exclude {
    my ($self) = @_;
    return $self->{_exclude};
}

#-----------------------------------------------------------------------------

sub include {
    my ($self) = @_;
    return $self->{_include};
}

#-----------------------------------------------------------------------------

sub in_place {
    my ($self) = @_;
    return $self->{_in_place};
}

#-----------------------------------------------------------------------------

sub only {
    my ($self) = @_;
    return $self->{_only};
}

#-----------------------------------------------------------------------------

sub profile_strictness {
    my ($self) = @_;
    return $self->{_profile_strictness};
}

#-----------------------------------------------------------------------------

sub single_transformer {
    my ($self) = @_;
    return $self->{_single_transformer};
}

#-----------------------------------------------------------------------------

sub verbose {
    my ($self) = @_;
    return $self->{_verbose};
}

#-----------------------------------------------------------------------------

sub color {
    my ($self) = @_;
    return $self->{_color};
}

#-----------------------------------------------------------------------------

sub pager {
    my ($self) = @_;
    return $self->{_pager};
}

#-----------------------------------------------------------------------------

sub detail {
    my ($self) = @_;
    return $self->{_detail};
}

#-----------------------------------------------------------------------------

sub force {
    my ($self) = @_;
    return $self->{_force};
}

#-----------------------------------------------------------------------------

sub top {
    my ($self) = @_;
    return $self->{_top};
}

#-----------------------------------------------------------------------------

sub color_necessity_highest {
    my ($self) = @_;
    return $self->{_color_necessity_highest};
}

#-----------------------------------------------------------------------------

sub color_necessity_high {
    my ($self) = @_;
    return $self->{_color_necessity_high};
}

#-----------------------------------------------------------------------------

sub color_necessity_medium {
    my ($self) = @_;
    return $self->{_color_necessity_medium};
}

#-----------------------------------------------------------------------------

sub color_necessity_low {
    my ($self) = @_;
    return $self->{_color_necessity_low};
}

#-----------------------------------------------------------------------------

sub color_necessity_lowest {
    my ($self) = @_;
    return $self->{_color_necessity_lowest};
}

#-----------------------------------------------------------------------------

sub program_extensions {
    my ($self) = @_;
    return $self->{_program_extensions};
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::ToPerl6::OptionsProcessor - The global configuration default values, combined with command-line values.


=head1 DESCRIPTION

This is a helper class that encapsulates the default parameters for
constructing a L<Perl::ToPerl6::Config|Perl::ToPerl6::Config> object.
There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C< new( %DEFAULT_PARAMS ) >

Returns a reference to a new C<Perl::ToPerl6::OptionsProcessor> object.
You can override the coded defaults by passing in name-value pairs
that correspond to the methods listed below.

This is usually only invoked by
L<Perl::ToPerl6::UserProfile|Perl::ToPerl6::UserProfile>, which passes
in the global values from a F<.perlmogrifyrc> file.  This object
contains no information for individual Transformers.

=back

=head1 METHODS

=over

=item C< exclude() >

Returns a reference to a list of the default exclusion patterns.  If
onto by
L<Perl::ToPerl6::TransformeryParameter|Perl::ToPerl6::TransformerParameter>.  there
are no default exclusion patterns, then the list will be empty.


=item C< detail() >

Returns the default value of the C<detail> setting (0, 1..5)


=item C< force() >

Returns the default value of the C<force> flag (Either 1 or 0).


=item C< include() >

Returns a reference to a list of the default inclusion patterns.  If
there are no default exclusion patterns, then the list will be empty.


=item C< in_place() >

Returns the default value of the C<in_place> flag (Either 1 or 0).


=item C< only() >

Returns the default value of the C<only> flag (Either 1 or 0).


=item C< profile_strictness() >

Returns the default value of C<profile_strictness> as an unvalidated
string.


=item C< single_transformer() >

Returns the default C<single-transformer> pattern.  (As a string.)


=item C< necessity() >

Returns the default C<necessity> setting. (1..5).


=item C< theme() >

Returns the default C<theme> setting. (As a string).


=item C< top() >

Returns the default C<top> setting. (Either 0 or a positive integer).


=item C< verbose() >

Returns the default C<verbose> setting. (Either a number or format
string).


=item C< color() >

Returns the default C<color> setting. (Either 1 or 0).


=item C< pager() >

Returns the default C<pager> setting. (Either empty string or the pager
command string).


=item C< color_necessity_highest() >

Returns the color to be used for coloring highest necessity transformations.

=item C< color_necessity_high() >

Returns the color to be used for coloring high necessity transformations.

=item C< color_necessity_medium() >

Returns the color to be used for coloring medium necessity transformations.

=item C< color_necessity_low() >

Returns the color to be used for coloring low necessity transformations.

=item C< color_necessity_lowest() >

Returns the color to be used for coloring lowest necessity transformations.

=item C< program_extensions() >

Returns a reference to the array of file name extensions to be interpreted as
representing Perl programs.

=back


=head1 SEE ALSO

L<Perl::ToPerl6::Config|Perl::ToPerl6::Config>,
L<Perl::ToPerl6::UserProfile|Perl::ToPerl6::UserProfile>


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
