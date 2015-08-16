package Perl::ToPerl6::Module::Build;

use 5.006001;

use strict;
use warnings;

our $VERSION = '0.031';

use Carp;
use English qw< $OS_ERROR $EXECUTABLE_NAME -no_match_vars >;


use base 'Perl::ToPerl6::Module::Build::Standard';


sub ACTION_transformersummary {
    my ($self) = @_;

    require Perl::ToPerl6::TransformerSummaryGenerator;
    Perl::ToPerl6::TransformerSummaryGenerator->import(
        qw< generate_transformer_summary >
    );

    my $transformer_summary_file = generate_transformer_summary();
    $self->add_to_cleanup( $transformer_summary_file );

    return;
}


sub ACTION_nytprof {
    my ($self) = @_;

    $self->depends_on('build');
    $self->_run_nytprof();

    return;
}


sub authortest_dependencies {
    my ($self) = @_;

    $self->depends_on('transformersummary');
    $self->SUPER::authortest_dependencies();

    return;
}


sub _run_nytprof {
    my ($self) = @_;

    eval { require Devel::NYTProf; 1 }
        or croak 'Devel::NYTProf is required to run nytprof';

    eval { require File::Which; File::Which->import('which'); 1 }
        or croak 'File::Which is required to run nytprof';

    my $nytprofhtml = which('nytprofhtml')
        or croak 'Could not find nytprofhtml in your PATH';

    my $this_perl = $EXECUTABLE_NAME;
    my @perl_args = qw(-Iblib/lib -d:NYTProf blib/script/perlmogrify);
    my @perlmogrify_args =
        qw<
            --noprofile
            --severity=1
            --theme=core
            --exclude=TidyCode
            --exclude=PodSpelling
            --exclude=RcsKeywords
            blib
        >;
    warn "Running: $this_perl @perl_args @perlmogrify_args\n";

    my $status_perlmogrify = system $this_perl, @perl_args, @perlmogrify_args;
    croak "perlmogrify failed with status $status_perlmogrify"
        if $status_perlmogrify == 1;

    my $status_nytprofhtml = system $nytprofhtml;
    croak "nytprofhtml failed with status $status_nytprofhtml"
        if $status_nytprofhtml;

    return;
}


1;


__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::Module::Build - Customization of L<Module::Build> for L<Perl::ToPerl6>.


=head1 DESCRIPTION

This is a custom subclass of L<Module::Build> (actually,
L<Perl::ToPerl6::Module::Build::Standard>) that enhances existing functionality
and adds more for the benefit of installing and developing L<Perl::ToPerl6>.
The following actions have been added or redefined:


=head1 ACTIONS

=over

=item transformersummary

Generates the F<TransformerSummary.pod> file.  This should only be used by
C<Perl::ToPerl6> developers.  This action is also invoked by the C<authortest>
action, so the F<TransformerSummary.pod> file will be generated whenever you create
a distribution with the C<dist> or C<distdir> targets.


=item nytprof

Runs perlmogrify under the L<Devel::NYTProf> profiler and generates
an HTML report in F<nytprof/index.html>.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
