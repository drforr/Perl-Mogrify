package Perl::ToPerl6::Config;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use List::MoreUtils qw(any none apply);
use Scalar::Util qw(blessed);

use Perl::ToPerl6::Exception::AggregateConfiguration;
use Perl::ToPerl6::Exception::Configuration;
use Perl::ToPerl6::Exception::Configuration::Option::Global::ParameterValue;
use Perl::ToPerl6::Exception::Fatal::Internal qw{ throw_internal };
use Perl::ToPerl6::TransformerFactory;
use Perl::ToPerl6::Theme qw( $RULE_INVALID_CHARACTER_REGEX cook_rule );
use Perl::ToPerl6::UserProfile qw();
use Perl::ToPerl6::Utils qw{
    :booleans :characters :severities :internal_lookup :classification
    :data_conversion
};
use Perl::ToPerl6::Utils::Constants qw<
    :profile_strictness
    $_MODULE_VERSION_TERM_ANSICOLOR
>;
use Perl::ToPerl6::Utils::DataConversion qw< boolean_to_number dor >;

#-----------------------------------------------------------------------------

Readonly::Scalar my $SINGLE_TRANSFORMER_CONFIG_KEY => 'single-transformer';

#-----------------------------------------------------------------------------
# Constructor

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {
    my ( $self, %args ) = @_;

    # -top or -theme imply that -necessity is 1, unless it is already defined
    if ( defined $args{-top} || defined $args{-theme} ) {
        $args{-necessity} ||= $NECESSITY_LOWEST;
    }

    my $errors = Perl::ToPerl6::Exception::AggregateConfiguration->new();

    # Construct the UserProfile to get default options.
    my $profile_source = $args{-profile}; # Can be file path or data struct
    my $profile = Perl::ToPerl6::UserProfile->new( -profile => $profile_source );
    my $options_processor = $profile->options_processor();
    $self->{_profile} = $profile;

    $self->_validate_and_save_profile_strictness(
        $args{'-profile-strictness'},
        $errors,
    );

    # If given, these options should always have a true value.
    $self->_validate_and_save_regex(
        'include', $args{-include}, $options_processor->include(), $errors
    );
    $self->_validate_and_save_regex(
        'exclude', $args{-exclude}, $options_processor->exclude(), $errors
    );
    $self->_validate_and_save_regex(
        $SINGLE_TRANSFORMER_CONFIG_KEY,
        $args{ qq/-$SINGLE_TRANSFORMER_CONFIG_KEY/ },
        $options_processor->single_transformer(),
        $errors,
    );
    $self->_validate_and_save_color_necessity(
        'color_necessity_highest', $args{'-color-necessity-highest'},
        $options_processor->color_necessity_highest(), $errors
    );
    $self->_validate_and_save_color_necessity(
        'color_necessity_high', $args{'-color-necessity-high'},
        $options_processor->color_necessity_high(), $errors
    );
    $self->_validate_and_save_color_necessity(
        'color_necessity_medium', $args{'-color-necessity-medium'},
        $options_processor->color_necessity_medium(), $errors
    );
    $self->_validate_and_save_color_necessity(
        'color_necessity_low', $args{'-color-necessity-low'},
        $options_processor->color_necessity_low(), $errors
    );
    $self->_validate_and_save_color_necessity(
        'color_necessity_lowest', $args{'-color-necessity-lowest'},
        $options_processor->color_necessity_lowest(), $errors
    );

    $self->_validate_and_save_verbosity($args{-verbose}, $errors);
    $self->_validate_and_save_necessity($args{-necessity}, $errors);
    $self->_validate_and_save_detail($args{-detail}, $errors);
    $self->_validate_and_save_top($args{-top}, $errors);
    $self->_validate_and_save_theme($args{-theme}, $errors);
    $self->_validate_and_save_pager($args{-pager}, $errors);
    $self->_validate_and_save_program_extensions(
        $args{'-program-extensions'}, $errors);

    # If given, these options can be true or false (but defined)
    # We normalize these to numeric values by multiplying them by 1;
    $self->{_force} = boolean_to_number( dor( $args{-force}, $options_processor->force() ) );
    $self->{_in_place}  = boolean_to_number( dor( $args{'-in-place'},  $options_processor->in_place()  ) );
    $self->{_only}  = boolean_to_number( dor( $args{-only},  $options_processor->only()  ) );
    $self->{_color} = boolean_to_number( dor( $args{-color}, $options_processor->color() ) );


    # Construct a Factory with the Profile
    my $factory =
        Perl::ToPerl6::TransformerFactory->new(
            -profile              => $profile,
            -errors               => $errors,
            '-profile-strictness' => $self->profile_strictness(),
        );
    $self->{_factory} = $factory;

    # Initialize internal storage for Transformers
    $self->{_all_transformers_enabled_or_not} = [];
    $self->{_transformers} = [];

    # "NONE" means don't load any transformers
    if ( not defined $profile_source or $profile_source ne 'NONE' ) {
        # Heavy lifting here...
        $self->_load_transformers($errors);
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub apply_transform {

    my ( $self, %args ) = @_;

    if ( not $args{-transformer} ) {
        throw_internal q{The -transformer argument is required};
    }

    my $transformer  = $args{-transformer};

    # If the -transformer is already a blessed object, then just add it directly.
    if ( blessed $transformer ) {
        $self->_apply_transform_if_enabled($transformer);
        return $self;
    }

    # NOTE: The "-config" option is supported for backward compatibility.
    my $params = $args{-params} || $args{-config};

    my $factory       = $self->{_factory};
    my $transformer_object =
        $factory->create_transformer(-name=>$transformer, -params=>$params);
    $self->_apply_transform_if_enabled($transformer_object);

    return $self;
}

#-----------------------------------------------------------------------------

sub _apply_transform_if_enabled {
    my ( $self, $transformer_object ) = @_;

    my $config = $transformer_object->__get_config()
        or throw_internal
            q{Transformer was not set up properly because it does not have }
                . q{a value for its config attribute.};

    push @{ $self->{_all_transformers_enabled_or_not} }, $transformer_object;
    if ( $transformer_object->initialize_if_enabled( $config ) ) {
        $transformer_object->__set_enabled($TRUE);
        push @{ $self->{_transformers} }, $transformer_object;
    }
    else {
        $transformer_object->__set_enabled($FALSE);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _load_transformers {

    my ( $self, $errors ) = @_;
    my $factory  = $self->{_factory};
    my @transformers = $factory->create_all_transformers( $errors );

    return if $errors->has_exceptions();

    for my $transformer ( @transformers ) {

        # If -single-transformer is true, only load transformers that match it
        if ( $self->single_transformer() ) {
            if ( $self->_transformer_is_single_transformer( $transformer ) ) {
                $self->apply_transform( -transformer => $transformer );
            }
            next;
        }

        # To load, or not to load -- that is the question.
        my $load_me = $self->only() ? $FALSE : $TRUE;

        $load_me = $FALSE if     $self->_transformer_is_disabled( $transformer );
        $load_me = $TRUE  if     $self->_transformer_is_enabled( $transformer );
        $load_me = $FALSE if     $self->_transformer_is_unimportant( $transformer );
        $load_me = $FALSE if not $self->_transformer_is_thematic( $transformer );
        $load_me = $TRUE  if     $self->_transformer_is_included( $transformer );
        $load_me = $FALSE if     $self->_transformer_is_excluded( $transformer );


        next if not $load_me;
        $self->apply_transform( -transformer => $transformer );
    }

    # When using -single-transformer, only one transformer should ever be loaded.
    if ($self->single_transformer() && scalar $self->transformers() != 1) {
        $self->_add_single_transformer_exception_to($errors);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _transformer_is_disabled {
    my ($self, $transformer) = @_;
    my $profile = $self->_profile();
    return $profile->transformer_is_disabled( $transformer );
}

#-----------------------------------------------------------------------------

sub _transformer_is_enabled {
    my ($self, $transformer) = @_;
    my $profile = $self->_profile();
    return $profile->transformer_is_enabled( $transformer );
}

#-----------------------------------------------------------------------------

sub _transformer_is_thematic {
    my ($self, $transformer) = @_;
    my $theme = $self->theme();
    return $theme->transformer_is_thematic( -transformer => $transformer );
}

#-----------------------------------------------------------------------------

sub _transformer_is_unimportant {
    my ($self, $transformer) = @_;
    my $transformer_necessity = $transformer->get_necessity();
    my $min_necessity    = $self->{_necessity};
    return $transformer_necessity < $min_necessity;
}

#-----------------------------------------------------------------------------

sub _transformer_is_included {
    my ($self, $transformer) = @_;
    my $transformer_long_name = ref $transformer;
    my @inclusions  = $self->include();
    return any { $transformer_long_name =~ m/$_/ixms } @inclusions;
}

#-----------------------------------------------------------------------------

sub _transformer_is_excluded {
    my ($self, $transformer) = @_;
    my $transformer_long_name = ref $transformer;
    my @exclusions  = $self->exclude();
    return any { $transformer_long_name =~ m/$_/ixms } @exclusions;
}

#-----------------------------------------------------------------------------

sub _transformer_is_single_transformer {
    my ($self, $transformer) = @_;

    my @patterns = $self->single_transformer();
    return if not @patterns;

    my $transformer_long_name = ref $transformer;
    return any { $transformer_long_name =~ m/$_/ixms } @patterns;
}

#-----------------------------------------------------------------------------

sub _new_global_value_exception {
    my ($self, @args) = @_;

    return
        Perl::ToPerl6::Exception::Configuration::Option::Global::ParameterValue
            ->new(@args);
}

#-----------------------------------------------------------------------------

sub _add_single_transformer_exception_to {
    my ($self, $errors) = @_;

    my $message_suffix = $EMPTY;
    my $patterns = join q{", "}, $self->single_transformer();

    if (scalar $self->transformers() == 0) {
        $message_suffix =
            q{did not match any transformers (in combination with }
                . q{other transformer restrictions).};
    }
    else {
        $message_suffix  = qq{matched multiple transformers:\n\t};
        $message_suffix .= join qq{,\n\t}, apply { chomp } sort $self->transformers();
    }

    $errors->add_exception(
        $self->_new_global_value_exception(
            option_name     => $SINGLE_TRANSFORMER_CONFIG_KEY,
            option_value    => $patterns,
            message_suffix  => $message_suffix,
        )
    );

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_regex {
    my ($self, $option_name, $args_value, $default_value, $errors) = @_;

    my $full_option_name;
    my $source;
    my @regexes;

    if ($args_value) {
        $full_option_name = "-$option_name";

        if (ref $args_value) {
            @regexes = @{ $args_value };
        }
        else {
            @regexes = ( $args_value );
        }
    }

    if (not @regexes) {
        $full_option_name = $option_name;
        $source = $self->_profile()->source();

        if (ref $default_value) {
            @regexes = @{ $default_value };
        }
        elsif ($default_value) {
            @regexes = ( $default_value );
        }
    }

    my $found_errors;
    foreach my $regex (@regexes) {
        eval { qr/$regex/ixms }
            or do {
                my $cleaned_error = $EVAL_ERROR || '<unknown reason>';
                $cleaned_error =~
                    s/ [ ] at [ ] .* Config [.] pm [ ] line [ ] \d+ [.] \n? \z/./xms;

                $errors->add_exception(
                    $self->_new_global_value_exception(
                        option_name     => $option_name,
                        option_value    => $regex,
                        source          => $source,
                        message_suffix  => qq{is not valid: $cleaned_error},
                    )
                );

                $found_errors = 1;
            }
    }

    if (not $found_errors) {
        my $option_key = $option_name;
        $option_key =~ s/ - /_/xmsg;

        $self->{"_$option_key"} = \@regexes;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_profile_strictness {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $profile_strictness;

    if ($args_value) {
        $option_name = '-profile-strictness';
        $profile_strictness = $args_value;
    }
    else {
        $option_name = 'profile-strictness';

        my $profile = $self->_profile();
        $source = $profile->source();
        $profile_strictness = $profile->options_processor()->profile_strictness();
    }

    if ( not $PROFILE_STRICTNESSES{$profile_strictness} ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $profile_strictness,
                source          => $source,
                message_suffix  => q{is not one of "}
                    . join ( q{", "}, (sort keys %PROFILE_STRICTNESSES) )
                    . q{".},
            )
        );

        $profile_strictness = $PROFILE_STRICTNESS_FATAL;
    }

    $self->{_profile_strictness} = $profile_strictness;

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_verbosity {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $verbosity;

    if ($args_value) {
        $option_name = '-verbose';
        $verbosity = $args_value;
    }
    else {
        $option_name = 'verbose';

        my $profile = $self->_profile();
        $source = $profile->source();
        $verbosity = $profile->options_processor()->verbose();
    }

    if (
            is_integer($verbosity)
        and not is_valid_numeric_verbosity($verbosity)
    ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $verbosity,
                source          => $source,
                message_suffix  =>
                    'is not the number of one of the pre-defined verbosity formats.',
            )
        );
    }
    else {
        $self->{_verbose} = $verbosity;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_necessity {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $necessity;

    if ($args_value) {
        $option_name = '-necessity';
        $necessity = $args_value;
    }
    else {
        $option_name = 'necessity';

        my $profile = $self->_profile();
        $source = $profile->source();
        $necessity = $profile->options_processor()->necessity();
    }

    if ( is_integer($necessity) ) {
        if (
            $necessity >= $NECESSITY_LOWEST and $necessity <= $NECESSITY_HIGHEST
        ) {
            $self->{_necessity} = $necessity;
        }
        else {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $necessity,
                    source          => $source,
                    message_suffix  =>
                        "is not between $NECESSITY_LOWEST (low) and $NECESSITY_HIGHEST (high).",
                )
            );
        }
    }
    elsif ( not any { $_ eq lc $necessity } @NECESSITY_NAMES ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $necessity,
                source          => $source,
                message_suffix  =>
                    q{is not one of the valid necessity names: "}
                        . join (q{", "}, @NECESSITY_NAMES)
                        . q{".},
            )
        );
    }
    else {
        $self->{_necessity} = necessity_to_number($necessity);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_top {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $top;

    if (defined $args_value and $args_value ne q{}) {
        $option_name = '-top';
        $top = $args_value;
    }
    else {
        $option_name = 'top';

        my $profile = $self->_profile();
        $source = $profile->source();
        $top = $profile->options_processor()->top();
    }

    if ( is_integer($top) and $top >= 0 ) {
        $self->{_top} = $top;
    }
    else {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $top,
                source          => $source,
                message_suffix  => q{is not a non-negative integer.},
            )
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_theme {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $theme_rule;

    if ($args_value) {
        $option_name = '-theme';
        $theme_rule = $args_value;
    }
    else {
        $option_name = 'theme';

        my $profile = $self->_profile();
        $source = $profile->source();
        $theme_rule = $profile->options_processor()->theme();
    }

    if ( $theme_rule =~ m/$RULE_INVALID_CHARACTER_REGEX/xms ) {
        my $bad_character = $1;

        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $theme_rule,
                source          => $source,
                message_suffix  =>
                    qq{contains an illegal character ("$bad_character").},
            )
        );
    }
    else {
        my $rule_as_code = cook_rule($theme_rule);
        $rule_as_code =~ s/ [\w\d]+ / 1 /gxms;

        # eval of an empty string does not reset $@ in Perl 5.6.
        local $EVAL_ERROR = $EMPTY;
        eval $rule_as_code;

        if ($EVAL_ERROR) {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $theme_rule,
                    source          => $source,
                    message_suffix  => q{is not syntactically valid.},
                )
            );
        }
        else {
            eval {
                $self->{_theme} =
                    Perl::ToPerl6::Theme->new( -rule => $theme_rule );
            }
                or do {
                    $errors->add_exception_or_rethrow( $EVAL_ERROR );
                };
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_pager {
    my ($self, $args_value, $errors) = @_;

    my $pager;
    if ( $args_value ) {
        $pager = defined $args_value ? $args_value : $EMPTY;
    }
    elsif ( $ENV{PERLMOGRIFY_PAGER} ) {
        $pager = $ENV{PERLMOGRIFY_PAGER};
    }
    else {
        my $profile = $self->_profile();
        $pager = $profile->options_processor()->pager();
    }

    if ($pager eq '$PAGER') {
        $pager = $ENV{PAGER};
    }
    $pager ||= $EMPTY;

    $self->{_pager} = $pager;

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_detail {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $detail;

    if ($args_value) {
        $option_name = '-detail';
        $detail = $args_value;
    }
    else {
        $option_name = 'detail';

        my $profile = $self->_profile();
        $source = $profile->source();
        $detail = $profile->options_processor()->detail();
    }

    if ( is_integer($detail) ) {
        if (
            $detail >= $NECESSITY_LOWEST and $detail <= $NECESSITY_HIGHEST
        ) {
            $self->{_detail} = $detail;
        }
        else {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $detail,
                    source          => $source,
                    message_suffix  =>
                        "is not between $NECESSITY_LOWEST (low) and $NECESSITY_HIGHEST (high).",
                )
            );
        }
    }
    elsif ( not any { $_ eq lc $detail } @NECESSITY_NAMES ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $detail,
                source          => $source,
                message_suffix  =>
                    q{is not one of the valid necessity names: "}
                        . join (q{", "}, @NECESSITY_NAMES)
                        . q{".},
            )
        );
    }
    else {
        $self->{_detail} = necessity_to_number($detail);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_color_necessity {
    my ($self, $option_name, $args_value, $default_value, $errors) = @_;

    my $source;
    my $color_necessity;
    my $full_option_name;

    if (defined $args_value) {
        $full_option_name = "-$option_name";
        $color_necessity = lc $args_value;
    }
    else {
        $full_option_name = $option_name;
        $source = $self->_profile()->source();
        $color_necessity = lc $default_value;
    }
    $color_necessity =~ s/ \s+ / /xmsg;
    $color_necessity =~ s/ \A\s+ //xms;
    $color_necessity =~ s/ \s+\z //xms;
    $full_option_name =~ s/ _ /-/xmsg;

    # Should we really be validating this?
    my $found_errors;
    if (
        eval {
            require Term::ANSIColor;
            Term::ANSIColor->VERSION( $_MODULE_VERSION_TERM_ANSICOLOR );
            1;
        }
    ) {
        $found_errors =
            not Term::ANSIColor::colorvalid( words_from_string($color_necessity) );
    }

    # If we do not have Term::ANSIColor we can not validate, but we store the
    # values anyway for the benefit of Perl::ToPerl6::ProfilePrototype.

    if ($found_errors) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $full_option_name,
                option_value    => $color_necessity,
                source          => $source,
                message_suffix  => 'is not valid.',
            )
        );
    }
    else {
        my $option_key = $option_name;
        $option_key =~ s/ - /_/xmsg;

        $self->{"_$option_key"} = $color_necessity;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_program_extensions {
    my ($self, $args_value, $errors) = @_;

    delete $self->{_program_extensions_as_regexes};

    my $extension_list = q{ARRAY} eq ref $args_value ?
        [map {words_from_string($_)} @{ $args_value }] :
        $self->_profile()->options_processor()->program_extensions();

    my %program_extensions = hashify( @{ $extension_list } );

    $self->{_program_extensions} = [keys %program_extensions];

    return;

}

#-----------------------------------------------------------------------------
# Begin ACCESSSOR methods

sub _profile {
    my ($self) = @_;
    return $self->{_profile};
}

#-----------------------------------------------------------------------------

sub all_transformers_enabled_or_not {
    my ($self) = @_;
    return @{ $self->{_all_transformers_enabled_or_not} };
}

#-----------------------------------------------------------------------------

sub transformers {
    my ($self) = @_;
    return @{ $self->{_transformers} };
}

#-----------------------------------------------------------------------------

sub exclude {
    my ($self) = @_;
    return @{ $self->{_exclude} };
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

sub include {
    my ($self) = @_;
    return @{ $self->{_include} };
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

sub necessity {
    my ($self) = @_;
    return $self->{_necessity};
}

#-----------------------------------------------------------------------------

sub single_transformer {
    my ($self) = @_;
    return @{ $self->{_single_transformer} };
}

#-----------------------------------------------------------------------------

sub theme {
    my ($self) = @_;
    return $self->{_theme};
}

#-----------------------------------------------------------------------------

sub top {
    my ($self) = @_;
    return $self->{_top};
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

sub pager  {
    my ($self) = @_;
    return $self->{_pager};
}

#-----------------------------------------------------------------------------

sub site_transformer_names {
    return Perl::ToPerl6::TransformerFactory::site_transformer_names();
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
    return @{ $self->{_program_extensions} };
}

#-----------------------------------------------------------------------------

sub program_extensions_as_regexes {
    my ($self) = @_;

    return @{ $self->{_program_extensions_as_regexes} }
        if $self->{_program_extensions_as_regexes};

    my %program_extensions = hashify( $self->program_extensions() );
    $program_extensions{'.PL'} = 1;
    return @{
        $self->{_program_extensions_as_regexes} = [
            map { qr< @{[quotemeta $_]} \z >smx } sort keys %program_extensions
        ]
    };
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords colour INI-style -params

=head1 NAME

Perl::ToPerl6::Config - The final derived Perl::ToPerl6 configuration, combined from any profile file and command-line parameters.


=head1 DESCRIPTION

Perl::ToPerl6::Config takes care of finding and processing
user-preferences for L<Perl::ToPerl6|Perl::ToPerl6>.  The Config object
defines which Transformer modules will be loaded into the Perl::ToPerl6
engine and how they should be configured.  You should never really
need to instantiate Perl::ToPerl6::Config directly because the
Perl::ToPerl6 constructor will do it for you.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C<< new(...) >>

Not properly documented because you shouldn't be using this.


=back

=head1 METHODS

=over

=item C<< apply_transform( -transformer => $transformer_name, -params => \%param_hash ) >>

Creates a Transformer object and loads it into this Config.  If the object
cannot be instantiated, it will throw a fatal exception.  Otherwise,
it returns a reference to this ToPerl6.

B<-transformer> is the name of a
L<Perl::ToPerl6::Transformer|Perl::ToPerl6::Transformer> subclass module.  The
C<'Perl::ToPerl6::Transformer'> portion of the name can be omitted for
brevity.  This argument is required.

B<-params> is an optional reference to a hash of Transformer parameters.
The contents of this hash reference will be passed into to the
constructor of the Transformer module.  See the documentation in the
relevant Transformer module for a description of the arguments it supports.


=item C< all_transformers_enabled_or_not() >

Returns a list containing references to all the Transformer objects that
have been seen.  Note that the state of these objects is not
trustworthy.  In particular, it is likely that some of them are not
prepared to examine any documents.


=item C< transformers() >

Returns a list containing references to all the Transformer objects that
have been enabled and loaded into this Config.


=item C< exclude() >

Returns the value of the C<-exclude> attribute for this Config.


=item C< include() >

Returns the value of the C<-include> attribute for this Config.


=item C< detail() >

Returns the value of the C<-detail> attribute for this Config.


=item C< force() >

Returns the value of the C<-force> attribute for this Config.


=item C< in_place() >

Returns the value of the C<-in-place> attribute for this Config.


=item C< only() >

Returns the value of the C<-only> attribute for this Config.


=item C< profile_strictness() >

Returns the value of the C<-profile-strictness> attribute for this
Config.


=item C< necessity() >

Returns the value of the C<-necessity> attribute for this Config.


=item C< single_transformer() >

Returns the value of the C<-single-transformer> attribute for this Config.


=item C< theme() >

Returns the L<Perl::ToPerl6::Theme|Perl::ToPerl6::Theme> object that was
created for this Config.


=item C< top() >

Returns the value of the C<-top> attribute for this Config.


=item C< verbose() >

Returns the value of the C<-verbose> attribute for this Config.


=item C< color() >

Returns the value of the C<-color> attribute for this Config.


=item C< pager() >

Returns the value of the C<-pager> attribute for this Config.


=item C< color_necessity_highest() >

Returns the value of the C<-color-necessity-highest> attribute for this
Config.


=item C< color_necessity_high() >

Returns the value of the C<-color-necessity-high> attribute for this
Config.


=item C< color_necessity_medium() >

Returns the value of the C<-color-necessity-medium> attribute for this
Config.


=item C< color_necessity_low() >

Returns the value of the C<-color-necessity-low> attribute for this
Config.


=item C< color_necessity_lowest() >

Returns the value of the C<-color-necessity-lowest> attribute for this
Config.

=item C< program_extensions() >

Returns the value of the C<-program_extensions> attribute for this Config.
This is an array of the file name extensions that represent program files.

=item C< program_extensions_as_regexes() >

Returns the value of the C<-program_extensions> attribute for this Config, as
an array of case-sensitive regexes matching the ends of the file names that
represent program files.

=back


=head1 SUBROUTINES

Perl::ToPerl6::Config has a few static subroutines that are used
internally, but may be useful to you in some way.


=over

=item C<site_transformer_names()>

Returns a list of all the Transformer modules that are currently installed
in the Perl::ToPerl6:Transformer namespace.  These will include modules that
are distributed with Perl::ToPerl6 plus any third-party modules that
have been installed.


=back


=head1 CONFIGURATION

Most of the settings for Perl::ToPerl6 and each of the Transformer modules
can be controlled by a configuration file.  The default configuration
file is called F<.perlmogrifyrc>.
L<Perl::ToPerl6::Config|Perl::ToPerl6::Config> will look for this file
in the current directory first, and then in your home directory.
Alternatively, you can set the C<PERLMOGRIFY> environment variable to
explicitly point to a different file in another location.  If none of
these files exist, and the C<-profile> option is not given to the
constructor, then all Transformers will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks
that contain key-value pairs separated by '='. Comments should start
with '#' and can be placed on a separate line or after the name-value
pairs if you desire.

Default settings for Perl::ToPerl6 itself can be set B<before the first
named block.>  For example, putting any or all of these at the top of
your configuration file will set the default value for the
corresponding Perl::ToPerl6 constructor argument.

    necessity  = 3                                     #Integer from 1 to 5
    in_place  = 0                                     #Zero or One
    only      = 1                                     #Zero or One
    detail    = 0                                     #Integer from 1 to 5
    force     = 0                                     #Zero or One
    verbose   = 4                                     #Integer or format spec
    top       = 50                                    #A positive integer
    theme     = risky + (pbp * security) - cosmetic   #A theme expression
    include   = NamingConventions ClassHierarchies    #Space-delimited list
    exclude   = Variables  Modules::RequirePackage    #Space-delimited list
    color     = 1                                     #Zero or One
    color-necessity-highest = bold red                #Term::ANSIColor
    color-necessity-high = magenta                    #Term::ANSIColor
    color-necessity-medium =                          #no coloring
    color-necessity-low =                             #no coloring
    color-necessity-lowest =                          #no coloring
    program-extensions =                              #Space-delimited list

The remainder of the configuration file is a series of blocks like
this:

    [Perl::ToPerl6::Transformer::Category::TransformerName]
    necessity = 1
    set_themes = foo bar
    add_themes = baz
    arg1 = value1
    arg2 = value2

C<Perl::ToPerl6::Transformer::Category::TransformerName> is the full name of a
module that implements the transformer.  The Transformer modules distributed
with Perl::ToPerl6 have been grouped into categories according to the
table of contents in Damian Conway's book B<Perl Best Practices>. For
brevity, you can omit the C<'Perl::ToPerl6::Transformer'> part of the module
name.

C<necessity> is the level of importance you wish to assign to the
Transformer.  All Transformer modules are defined with a default necessity value
ranging from 1 (least severe) to 5 (most severe).  However, you may
disagree with the default necessity and choose to give it a higher or
lower necessity, based on your own coding philosophy.

The remaining key-value pairs are configuration parameters that will
be passed into the constructor of that Transformer.  The constructors for
most Transformer modules do not support arguments, and those that do should
have reasonable defaults.  See the documentation on the appropriate
Transformer module for more details.

Instead of redefining the necessity for a given Transformer, you can
completely disable a Transformer by prepending a '-' to the name of the
module in your configuration file.  In this manner, the Transformer will
never be loaded, regardless of the C<-necessity> given to the
Perl::ToPerl6::Config constructor.

A simple configuration might look like this:

    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequireUseStrict]
    necessity = 5

    [TestingAndDebugging::RequireUseWarnings]
    necessity = 5

    #--------------------------------------------------------------
    # I think these are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    necessity = 2

    [ControlStructures::ProhibitPostfixControls]
    allow = if unless  #My custom configuration
    necessity = 2

    #--------------------------------------------------------------
    # Give these transformers a custom theme.  I can activate just
    # these transformers by saying (-theme => 'larry + curly')

    [Modules::RequireFilenameMatchesPackage]
    add_themes = larry

    [TestingAndDebugging::RequireTestLables]
    add_themes = curly moe

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::Capitalization]
    [-ValuesAndExpressions::ProhibitMagicNumbers]

    #--------------------------------------------------------------
    # For all other Transformers, I accept the default necessity, theme
    # and other parameters, so no additional configuration is
    # required for them.

For additional configuration examples, see the F<perlmogrifyrc> file
that is included in this F<t/examples> directory of this distribution.


=head1 THE POLICIES

A large number of Transformer modules are distributed with Perl::ToPerl6.
They are described briefly in the companion document
L<Perl::ToPerl6::TransformerSummary|Perl::ToPerl6::TransformerSummary> and in more
detail in the individual modules themselves.


=head1 TRANSFORMER THEMES

Each Transformer is defined with one or more "themes".  Themes can be used
to create arbitrary groups of Transformers.  They are intended to provide
an alternative mechanism for selecting your preferred set of Transformers.
For example, you may wish disable a certain subset of Transformers when
analyzing test programs.  Conversely, you may wish to enable only a
specific subset of Transformers when analyzing modules.

The Transformers that ship with Perl::ToPerl6 are have been broken into the
following themes.  This is just our attempt to provide some basic
logical groupings.  You are free to invent new themes that suit your
needs.

    THEME             DESCRIPTION
    --------------------------------------------------------------------------
    core              All transformers that ship with Perl::ToPerl6
    pbp               Transformers that come directly from "Perl Best Practices"
    bugs              Transformers that prevent or reveal bugs
    maintenance       Transformers that affect the long-term health of the code
    cosmetic          Transformers that only have a superficial effect
    complexity        Transformers that specificaly relate to code complexity
    security          Transformers that relate to security issues
    tests             Transformers that are specific to test programs

Say C<`perlmogrify -list`> to get a listing of all available transformers
and the themes that are associated with each one.  You can also change
the theme for any Transformer in your F<.perlmogrifyrc> file.  See the
L<"CONFIGURATION"> section for more information about that.

Using the C<-theme> option, you can combine theme names with
mathematical and boolean operators to create an arbitrarily complex
expression that represents a custom "set" of Transformers.  The following
operators are supported

   Operator       Alternative         Meaning
   ----------------------------------------------------------------------------
   *              and                 Intersection
   -              not                 Difference
   +              or                  Union

Operator precedence is the same as that of normal mathematics.  You
can also use parenthesis to enforce precedence.  Here are some
examples:

   Expression                  Meaning
   ----------------------------------------------------------------------------
   pbp * bugs                  All transformers that are "pbp" AND "bugs"
   pbp and bugs                Ditto

   bugs + cosmetic             All transformers that are "bugs" OR "cosmetic"
   bugs or cosmetic            Ditto

   pbp - cosmetic              All transformers that are "pbp" BUT NOT "cosmetic"
   pbp not cosmetic            Ditto

   -maintenance                All transformers that are NOT "maintenance"
   not maintenance             Ditto

   (pbp - bugs) * complexity     All transformers that are "pbp" BUT NOT "bugs",
                                    AND "complexity"
   (pbp not bugs) and complexity  Ditto

Theme names are case-insensitive.  If C<-theme> is set to an empty
string, then it is equivalent to the set of all Transformers.  A theme
name that doesn't exist is equivalent to an empty set.  Please See
L<http://en.wikipedia.org/wiki/Set> for a discussion on set theory.


=head1 SEE ALSO

L<Perl::ToPerl6::OptionsProcessor|Perl::ToPerl6::OptionsProcessor>,
L<Perl::ToPerl6::UserProfile|Perl::ToPerl6::UserProfile>


=head1 AUTHOR

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
