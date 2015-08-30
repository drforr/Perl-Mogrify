package Perl::ToPerl6::TransformerFactory;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use File::Spec::Unix qw();
use List::Util qw(max);
use List::MoreUtils qw(any);

use Perl::ToPerl6::Utils qw{
    :characters
    $TRANSFORMER_NAMESPACE
    :data_conversion
    transformer_long_name
    transformer_short_name
    :internal_lookup
};
use Perl::ToPerl6::TransformerConfig;
use Perl::ToPerl6::Exception::AggregateConfiguration;
use Perl::ToPerl6::Exception::Configuration;
use Perl::ToPerl6::Exception::Fatal::Generic qw{ throw_generic };
use Perl::ToPerl6::Exception::Fatal::Internal qw{ throw_internal };
use Perl::ToPerl6::Exception::Fatal::TransformerDefinition
    qw{ throw_transformer_definition };
use Perl::ToPerl6::Exception::Configuration::NonExistentTransformer qw< >;
use Perl::ToPerl6::Utils::Constants qw{ :profile_strictness };

use Exception::Class;   # this must come after "use P::C::Exception::*"

#-----------------------------------------------------------------------------

# Globals.  Ick!
my @site_transformer_names = ();

#-----------------------------------------------------------------------------

# Blech!!!  This is ug-lee.  Belongs in the constructor.  And it shouldn't be
# called "test" mode.
sub import {

    my ( $class, %args ) = @_;
    my $test_mode = $args{-test};
    my $extra_test_transformers = $args{'-extra-test-transformers'};

    if ( not @site_transformer_names ) {
        my $eval_worked = eval {
            require Module::Pluggable;
            Module::Pluggable->import(search_path => $TRANSFORMER_NAMESPACE,
                                      require => 1, inner => 0);
            @site_transformer_names = plugins(); #Exported by Module::Pluggable
            1;
        };

        if (not $eval_worked) {
            if ( $EVAL_ERROR ) {
                throw_generic
                    qq<Can't load Transformers from namespace "$TRANSFORMER_NAMESPACE": $EVAL_ERROR>;
            }

            throw_generic
                qq<Can't load Transformers from namespace "$TRANSFORMER_NAMESPACE" for an unknown reason.>;
        }

        if ( not @site_transformer_names ) {
            throw_generic
                qq<No Transformers found in namespace "$TRANSFORMER_NAMESPACE".>;
        }
    }

    # In test mode, only load native transformers, not third-party ones.  So this
    # filters out any transformer that was loaded from within a directory called
    # "blib".  During the usual "./Build test" process this works fine,
    # but it doesn't work if you are using prove to test against the code
    # directly in the lib/ directory.

    if ( $test_mode && any {m/\b blib \b/xms} @INC ) {
        @site_transformer_names = _modules_from_blib( @site_transformer_names );

        if ($extra_test_transformers) {
            my @extra_transformer_full_names =
                map { "${TRANSFORMER_NAMESPACE}::$_" } @{$extra_test_transformers};

            push @site_transformer_names, @extra_transformer_full_names;
        }
    }

    return 1;
}

#-----------------------------------------------------------------------------
# Shuffle transformer order based on preferences, if any.

# Transformers can request to run before or after a given list of other
# transformers. This code rewrites the list as follows:
#
# If transformer A requests to be run *before* transformer B, then we instead
# state that transformer B must be run *after* transformer A. It's the logical
# dual, but having only one kind of dependency to deal with makes it easier.
#
sub _invert_dependencies {
    my ($dependencies) = @_;

    for my $name ( keys %{ $dependencies } ) {
        next unless $dependencies->{$name}{before};
        for my $_name ( keys %{ $dependencies->{$name}{before} } ) {
            $dependencies->{$_name}{after}{$name} = 1;
        }
    }
}

# Collect the preferences for all the transformers we want to run.
#
sub _collect_preferences {
    my (@transformers) = @_;
    my $preferences;

    for my $transformer ( @transformers ) {
        my $ref_name = ref($transformer);
        $ref_name =~ s< ^ Perl\::ToPerl6\::Transformer\:: ><>x;
        $preferences->{$ref_name} = { };

        # Get the list of transformers this module wants to run *after*.
        #
        if ( $transformer->can('run_before') ) {
            my @before = $transformer->run_before();
            $preferences->{$ref_name}{before} = { map {
                s< ^ Perl\::ToPerl6\::Transformer\:: ><>x;
                $_ => 1
            } @before };
        }

        # Get the list of transformers this module wants to run *before*.
        #
        if ( $transformer->can('run_after') ) {
            my @after = $transformer->run_after();
            $preferences->{$ref_name}{after} = { map {
                s< ^ Perl\::ToPerl6\::Transformer\:: ><>x;
                $_ => 1
            } @after };
        }
    }

    return $preferences;
}

sub _validate_preferences {
    my ($preferences) = @_;

    for my $k ( keys %{ $preferences } ) {
        if ( $preferences->{$k} and
             $preferences->{$k}{after} ) {
            for my $_k ( keys %{ $preferences->{$k}{after} } ) {
                next if exists $preferences->{$_k};
die "Module $k wanted to run after module $_k, which was not found!\n";
            }
        }
        if ( $preferences->{$k} and
             $preferences->{$k}{before} ) {
            for my $_k ( keys %{ $preferences->{$k}{before} } ) {
                next if exists $preferences->{$_k};
die "Module $k wanted to run before module $_k, which was not found!\n";
            }
        }
    }
}

# Transformers can now request to be run before or after a given transformer.
# Or transformers.
#
# We honor those requests here, by collecting the transformers, calling
# ->run_before() and/or ->run_after(), to get what transformers they must
# run after or before.
#
# Then we restate the 'before' requests in terms of 'after', dying for the
# moment if we can't find a module that a given module wants to run 'after'.
#
# After restating 'before' as 'after', we sort the modules in order of
# preference, then return the list in preference order.
#
sub topological_sort {
    my @transformers = @_;
    my @ordered;

    my %object;
    for my $transformer ( @transformers ) {
        my $ref_name = ref $transformer;
        $ref_name =~ s< ^ Perl\::ToPerl6\::Transformer\:: ><>x;

        $object{$ref_name} = $transformer;
    }

    my $preferences = _collect_preferences(@transformers);
    _validate_preferences($preferences);

    _invert_dependencies($preferences);

    # This algorithm can potentially loop if it encounters a cycle in the
    # dependencies.
    #
    # Specifically, the hash could look like this at the end:
    # %foo = ( A => { after => { B => 1 } }, B => { after => { A => 1 } } );
    # In which case this algorithm wouldn't terminate.
    # So we count down from the number of keys in the original hash.
    # This should give us plenty of time to detect cycles.
    #
    # The cycle could be arbitrarily long, and while there are fancy
    # algorithms to detect those, I'm not going to bother.
    #
    # Keeping the module names in a stable order reduces the likelihood
    # that a cycle will "trap" (I.E. come before) a module that's not
    # involved in the cycle. It still could happen, but I'll worry about that
    # later on.
    #
    my %final;
    my $iterations = keys %{ $preferences };

    while( keys %{ $preferences } ) {
        last if $iterations-- <= 0; # DO NOT REMOVE THIS.
        for my $name ( sort keys %{ $preferences } ) {

            # If a module needs to run after one or more modules, try to
            # satisfy its request.
            #
            if ( $preferences->{$name}{after} ) {

                # Walk the list of modules it needs to run after.
                #
                my $max = 0;
                for my $_name ( keys %{ $preferences->{$name}{after} } ) {

                    # If it needs to run after a module we haven't placed in
                    # order, then abandon the loop.
                    #
                    if ( !exists $final{$_name} ) {
                        $max = -1;
                        last;
                    }
                    $max = max($final{$_name},$max);
                }

                # If we haven't abandoned the loop, then
                # add the module *after* the last module in order
                # and delete the module from the preferences list.
                #
                if ( $max >= 0 ) {
                   $final{$name} = $max + 1;
                   delete $preferences->{$name};
                }
            }

            # The module doesn't need to be run after any given module.
            # So put it directly on the list, in group 0.
            #
            else {
               $final{$name} = 0;
               delete $preferences->{$name};
            }
        }
    }

    # If there are any keys remaining in the preferences array, it's possible
    # that the algorithm didn't sort dependencies correctly, but it is
    # vastly more likely to be the case that we've encountered a cycle.
    # Die, telling the user what happened.
    #
    if ( keys %{ $preferences } ) {
        die "Found a preference loop among: " . join("\n", keys %{ $preferences });
    }

    my %inverse;
    push @{$inverse{$final{$_}}}, $_ for keys %final;
    for ( sort keys %inverse ) {
        push @ordered, map { $object{$_} } @{$inverse{$_}};
    }

    return @ordered;
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
                    : Perl::ToPerl6::Exception::AggregateConfiguration->new();
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

sub create_transformer {

    my ($self, %args ) = @_;

    my $transformer_name = $args{-name}
        or throw_internal q{The -name argument is required};

    # Normalize transformer name to a fully-qualified package name
    $transformer_name = transformer_long_name( $transformer_name );
    my $transformer_short_name = transformer_short_name( $transformer_name );


    # Get the transformer parameters from the user profile if they were
    # not given to us directly.  If none exist, use an empty hash.
    my $profile = $self->_profile();
    my $transformer_config;
    if ( $args{-params} ) {
        $transformer_config =
            Perl::ToPerl6::TransformerConfig->new(
                $transformer_short_name, $args{-params}
            );
    }
    else {
        $transformer_config = $profile->transformer_params($transformer_name);
        $transformer_config ||=
            Perl::ToPerl6::TransformerConfig->new( $transformer_short_name );
    }

    # Pull out base parameters.
    return $self->_instantiate_transformer( $transformer_name, $transformer_config );
}

#-----------------------------------------------------------------------------

sub create_all_transformers {

    my ( $self, $incoming_errors ) = @_;

    my $errors =
        $incoming_errors
            ? $incoming_errors
            : Perl::ToPerl6::Exception::AggregateConfiguration->new();
    my @transformers;

    foreach my $name ( site_transformer_names() ) {
        my $transformer = eval { $self->create_transformer( -name => $name ) };

        $errors->add_exception_or_rethrow( $EVAL_ERROR );

        if ( $transformer ) {
            push @transformers, $transformer;
        }
    }

    if ( not $incoming_errors and $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    my @sorted = topological_sort(@transformers);

    return @sorted;
}

#-----------------------------------------------------------------------------

sub site_transformer_names {
    my @sorted_transformer_names = sort @site_transformer_names;
    return @sorted_transformer_names;
}

#-----------------------------------------------------------------------------

sub _profile {
    my ($self) = @_;

    return $self->{_profile};
}

#-----------------------------------------------------------------------------

# This two-phase initialization is caused by the historical lack of a
# requirement for Transformers to invoke their super-constructor.
sub _instantiate_transformer {
    my ($self, $transformer_name, $transformer_config) = @_;

    $transformer_config->set_profile_strictness( $self->{_profile_strictness} );

    my $transformer = eval { $transformer_name->new( %{$transformer_config} ) };
    _handle_transformer_instantiation_exception(
        $transformer_name,
        $transformer,        # Note: being used as a boolean here.
        $EVAL_ERROR,
    );

    $transformer->__set_config( $transformer_config );

    my $eval_worked = eval { $transformer->__set_base_parameters(); 1; };
    _handle_transformer_instantiation_exception(
        $transformer_name, $eval_worked, $EVAL_ERROR,
    );

    return $transformer;
}

sub _handle_transformer_instantiation_exception {
    my ($transformer_name, $eval_worked, $eval_error) = @_;

    if (not $eval_worked) {
        if ($eval_error) {
            my $exception = Exception::Class->caught();

            if (ref $exception) {
                $exception->rethrow();
            }

            throw_transformer_definition(
                qq<Unable to create transformer "$transformer_name": $eval_error>);
        }

        throw_transformer_definition(
            qq<Unable to create transformer "$transformer_name" for an unknown reason.>);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_transformers_in_profile {
    my ($self, $errors) = @_;

    my $profile = $self->_profile();
    my %known_transformers = hashify( $self->site_transformer_names() );

    for my $transformer_name ( $profile->listed_transformers() ) {
        if ( not exists $known_transformers{$transformer_name} ) {
            my $message = qq{Transformer "$transformer_name" is not installed.};

            if ( $errors ) {
                $errors->add_exception(
                    Perl::ToPerl6::Exception::Configuration::NonExistentTransformer->new(
                        transformer  => $transformer_name,
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

Perl::ToPerl6::TransformerFactory - Instantiates Transformer objects.


=head1 DESCRIPTION

This is a helper class that instantiates
L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer> objects with the user's
preferred parameters. There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C<< new( -profile => $profile, -errors => $config_errors ) >>

Returns a reference to a new Perl::ToPerl6::TransformerFactory object.

B<-profile> is a reference to a
L<Perl::ToPerl6::UserProfile|Perl::ToPerl6::UserProfile> object.  This
argument is required.

B<-errors> is a reference to an instance of
L<Perl::ToPerl6::ConfigErrors|Perl::ToPerl6::ConfigErrors>.  This
argument is optional.  If specified, than any problems found will be
added to the object.


=back


=head1 METHODS

=over

=item C<< create_transformer( -name => $transformer_name, -params => \%param_hash ) >>

Creates one Transformer object.  If the object cannot be instantiated, it
will throw a fatal exception.  Otherwise, it returns a reference to
the new Transformer object.

B<-name> is the name of a L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer>
subclass module.  The C<'Perl::ToPerl6::Transformer'> portion of the name
can be omitted for brevity.  This argument is required.

B<-params> is an optional reference to hash of parameters that will be
passed into the constructor of the Transformer.  If C<-params> is not
defined, we will use the appropriate Transformer parameters from the
L<Perl::ToPerl6::UserProfile|Perl::ToPerl6::UserProfile>.

Note that the Transformer will not have had
L<Perl::ToPerl6::Transformer/"initialize_if_enabled"> invoked on it, so it
may not yet be usable.


=item C< create_all_transformers() >

Constructs and returns one instance of each
L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer> subclass that is
installed on the local system.  Each Transformer will be created with the
appropriate parameters from the user's configuration profile.

Note that the Transformers will not have had
L<Perl::ToPerl6::Transformer/"initialize_if_enabled"> invoked on them, so
they may not yet be usable.


=back


=head1 SUBROUTINES

Perl::ToPerl6::TransformerFactory has a few static subroutines that are used
internally, but may be useful to you in some way.

=over

=item C<topological_sort( @transformers )>

Given a list of Transformer objects, reorder them into the order they need to
be run. Variables::FormatSpecialVariables needs to reformat $0 before
Variables::FormatMatchVariables transforms $1 into $0, for example. If you need
to specify that a Transformer must be run before or after a given transformer
or list of transformers, then in your Transformer create a C<sub run_before()>
and/or C<sub run_after()> which returns a list of transformers that it must
run before and/or after.

If a transformer you specified doesn't exist, your transformer code should
still run, but with a warning.

=item C<site_transformer_names()>

Returns a list of all the Transformer modules that are currently installed
in the Perl::ToPerl6:Transformer namespace.  These will include modules that
are distributed with Perl::ToPerl6 plus any third-party modules that
have been installed.


=back


=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>


=head1 AUTHOR EMERITUS

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2015 Jeffrey Goff. All rights reserved.

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
