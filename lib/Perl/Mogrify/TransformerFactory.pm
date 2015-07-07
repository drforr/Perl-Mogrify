package Perl::Mogrify::TransformerFactory;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use File::Spec::Unix qw();
use List::MoreUtils qw(any);

use Perl::Mogrify::Utils qw{
    :characters
    $POLICY_NAMESPACE
    :data_conversion
    policy_long_name
    policy_short_name
    :internal_lookup
};
use Perl::Mogrify::TransformerConfig;
use Perl::Mogrify::Exception::AggregateConfiguration;
use Perl::Mogrify::Exception::Configuration;
use Perl::Mogrify::Exception::Fatal::Generic qw{ throw_generic };
use Perl::Mogrify::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Mogrify::Exception::Fatal::TransformerDefinition
    qw{ throw_policy_definition };
use Perl::Mogrify::Exception::Configuration::NonExistentTransformer qw< >;
use Perl::Mogrify::Utils::Constants qw{ :profile_strictness };

use Exception::Class;   # this must come after "use P::C::Exception::*"

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

# Globals.  Ick!
my @site_policy_names = ();

#-----------------------------------------------------------------------------

# Blech!!!  This is ug-lee.  Belongs in the constructor.  And it shouldn't be
# called "test" mode.
sub import {

    my ( $class, %args ) = @_;
    my $test_mode = $args{-test};
    my $extra_test_transformers = $args{'-extra-test-transformers'};

    if ( not @site_policy_names ) {
        my $eval_worked = eval {
            require Module::Pluggable;
            Module::Pluggable->import(search_path => $POLICY_NAMESPACE,
                                      require => 1, inner => 0);
            @site_policy_names = plugins(); #Exported by Module::Pluggable
            1;
        };

        if (not $eval_worked) {
            if ( $EVAL_ERROR ) {
                throw_generic
                    qq<Can't load Policies from namespace "$POLICY_NAMESPACE": $EVAL_ERROR>;
            }

            throw_generic
                qq<Can't load Policies from namespace "$POLICY_NAMESPACE" for an unknown reason.>;
        }

        if ( not @site_policy_names ) {
            throw_generic
                qq<No Policies found in namespace "$POLICY_NAMESPACE".>;
        }
    }

    # In test mode, only load native transformers, not third-party ones.  So this
    # filters out any policy that was loaded from within a directory called
    # "blib".  During the usual "./Build test" process this works fine,
    # but it doesn't work if you are using prove to test against the code
    # directly in the lib/ directory.

    if ( $test_mode && any {m/\b blib \b/xms} @INC ) {
        @site_policy_names = _modules_from_blib( @site_policy_names );

        if ($extra_test_transformers) {
            my @extra_policy_full_names =
                map { "${POLICY_NAMESPACE}::$_" } @{$extra_test_transformers};

            push @site_policy_names, @extra_policy_full_names;
        }
    }

    return 1;
}

#-----------------------------------------------------------------------------
# Some static helper subs

sub _modules_from_blib {
    my (@modules) = @_;
    return grep { _was_loaded_from_blib( _module2path($_) ) } @modules;
}

sub _module2path {
    my $module = shift || return;
    return File::Spec::Unix->catdir(split m/::/xms, $module) . '.pm';
}

sub _was_loaded_from_blib {
    my $path = shift || return;
    my $full_path = $INC{$path};
    return $full_path && $full_path =~ m/ (?: \A | \b b ) lib \b /xms;
}

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ($self, %args) = @_;

    my $profile = $args{-profile};
    $self->{_profile} = $profile
        or throw_internal q{The -profile argument is required};

    my $incoming_errors = $args{-errors};
    my $profile_strictness = $args{'-profile-strictness'};
    $profile_strictness ||= $PROFILE_STRICTNESS_DEFAULT;
    $self->{_profile_strictness} = $profile_strictness;

    if ( $profile_strictness ne $PROFILE_STRICTNESS_QUIET ) {
        my $errors;

        # If we're supposed to be strict or problems have already been found...
        if (
                $profile_strictness eq $PROFILE_STRICTNESS_FATAL
            or  ( $incoming_errors and @{ $incoming_errors->exceptions() } )
        ) {
            $errors =
                $incoming_errors
                    ? $incoming_errors
                    : Perl::Mogrify::Exception::AggregateConfiguration->new();
        }

        $self->_validate_transformers_in_profile( $errors );

        if (
                not $incoming_errors
            and $errors
            and $errors->has_exceptions()
        ) {
            $errors->rethrow();
        }
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub create_policy {

    my ($self, %args ) = @_;

    my $policy_name = $args{-name}
        or throw_internal q{The -name argument is required};

    # Normalize policy name to a fully-qualified package name
    $policy_name = policy_long_name( $policy_name );
    my $policy_short_name = policy_short_name( $policy_name );


    # Get the policy parameters from the user profile if they were
    # not given to us directly.  If none exist, use an empty hash.
    my $profile = $self->_profile();
    my $policy_config;
    if ( $args{-params} ) {
        $policy_config =
            Perl::Mogrify::TransformerConfig->new(
                $policy_short_name, $args{-params}
            );
    }
    else {
        $policy_config = $profile->policy_params($policy_name);
        $policy_config ||=
            Perl::Mogrify::TransformerConfig->new( $policy_short_name );
    }

    # Pull out base parameters.
    return $self->_instantiate_policy( $policy_name, $policy_config );
}

#-----------------------------------------------------------------------------

sub create_all_transformers {

    my ( $self, $incoming_errors ) = @_;

    my $errors =
        $incoming_errors
            ? $incoming_errors
            : Perl::Mogrify::Exception::AggregateConfiguration->new();
    my @transformers;

    foreach my $name ( site_policy_names() ) {
        my $policy = eval { $self->create_policy( -name => $name ) };

        $errors->add_exception_or_rethrow( $EVAL_ERROR );

        if ( $policy ) {
            push @transformers, $policy;
        }
    }

    if ( not $incoming_errors and $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return @transformers;
}

#-----------------------------------------------------------------------------

sub site_policy_names {
    my @sorted_policy_names = sort @site_policy_names;
    return @sorted_policy_names;
}

#-----------------------------------------------------------------------------

sub _profile {
    my ($self) = @_;

    return $self->{_profile};
}

#-----------------------------------------------------------------------------

# This two-phase initialization is caused by the historical lack of a
# requirement for Policies to invoke their super-constructor.
sub _instantiate_policy {
    my ($self, $policy_name, $policy_config) = @_;

    $policy_config->set_profile_strictness( $self->{_profile_strictness} );

    my $policy = eval { $policy_name->new( %{$policy_config} ) };
    _handle_policy_instantiation_exception(
        $policy_name,
        $policy,        # Note: being used as a boolean here.
        $EVAL_ERROR,
    );

    $policy->__set_config( $policy_config );

    my $eval_worked = eval { $policy->__set_base_parameters(); 1; };
    _handle_policy_instantiation_exception(
        $policy_name, $eval_worked, $EVAL_ERROR,
    );

    return $policy;
}

sub _handle_policy_instantiation_exception {
    my ($policy_name, $eval_worked, $eval_error) = @_;

    if (not $eval_worked) {
        if ($eval_error) {
            my $exception = Exception::Class->caught();

            if (ref $exception) {
                $exception->rethrow();
            }

            throw_policy_definition(
                qq<Unable to create policy "$policy_name": $eval_error>);
        }

        throw_policy_definition(
            qq<Unable to create policy "$policy_name" for an unknown reason.>);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_transformers_in_profile {
    my ($self, $errors) = @_;

    my $profile = $self->_profile();
    my %known_transformers = hashify( $self->site_policy_names() );

    for my $policy_name ( $profile->listed_transformers() ) {
        if ( not exists $known_transformers{$policy_name} ) {
            my $message = qq{Transformer "$policy_name" is not installed.};

            if ( $errors ) {
                $errors->add_exception(
                    Perl::Mogrify::Exception::Configuration::NonExistentTransformer->new(
                        policy  => $policy_name,
                    )
                );
            }
            else {
                warn qq{$message\n};
            }
        }
    }

    return;
}

#-----------------------------------------------------------------------------

1;

__END__


=pod

=for stopwords TransformerFactory -params

=head1 NAME

Perl::Mogrify::TransformerFactory - Instantiates Transformer objects.


=head1 DESCRIPTION

This is a helper class that instantiates
L<Perl::Mogrify::Transformer|Perl::Mogrify::Transformer> objects with the user's
preferred parameters. There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C<< new( -profile => $profile, -errors => $config_errors ) >>

Returns a reference to a new Perl::Mogrify::TransformerFactory object.

B<-profile> is a reference to a
L<Perl::Mogrify::UserProfile|Perl::Mogrify::UserProfile> object.  This
argument is required.

B<-errors> is a reference to an instance of
L<Perl::Mogrify::ConfigErrors|Perl::Mogrify::ConfigErrors>.  This
argument is optional.  If specified, than any problems found will be
added to the object.


=back


=head1 METHODS

=over

=item C<< create_policy( -name => $policy_name, -params => \%param_hash ) >>

Creates one Transformer object.  If the object cannot be instantiated, it
will throw a fatal exception.  Otherwise, it returns a reference to
the new Transformer object.

B<-name> is the name of a L<Perl::Mogrify::Transformer|Perl::Mogrify::Transformer>
subclass module.  The C<'Perl::Mogrify::Transformer'> portion of the name
can be omitted for brevity.  This argument is required.

B<-params> is an optional reference to hash of parameters that will be
passed into the constructor of the Transformer.  If C<-params> is not
defined, we will use the appropriate Transformer parameters from the
L<Perl::Mogrify::UserProfile|Perl::Mogrify::UserProfile>.

Note that the Transformer will not have had
L<Perl::Mogrify::Transformer/"initialize_if_enabled"> invoked on it, so it
may not yet be usable.


=item C< create_all_transformers() >

Constructs and returns one instance of each
L<Perl::Mogrify::Transformer|Perl::Mogrify::Transformer> subclass that is
installed on the local system.  Each Transformer will be created with the
appropriate parameters from the user's configuration profile.

Note that the Policies will not have had
L<Perl::Mogrify::Transformer/"initialize_if_enabled"> invoked on them, so
they may not yet be usable.


=back


=head1 SUBROUTINES

Perl::Mogrify::TransformerFactory has a few static subroutines that are used
internally, but may be useful to you in some way.

=over

=item C<site_policy_names()>

Returns a list of all the Transformer modules that are currently installed
in the Perl::Mogrify:Transformer namespace.  These will include modules that
are distributed with Perl::Mogrify plus any third-party modules that
have been installed.


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
