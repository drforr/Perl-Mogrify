package Perl::ToPerl6::TransformerSummaryGenerator;

use 5.006001;
use strict;
use warnings;

use Exporter 'import';

use lib qw< blib lib >;
use Carp qw< confess >;
use English qw< -no_match_vars >;

use Perl::ToPerl6::Config;
use Perl::ToPerl6::Exception::IO ();
use Perl::ToPerl6::TransformerFactory (-test => 1);
use Perl::ToPerl6::Utils qw< :characters >;
use Perl::ToPerl6::Utils::POD qw< get_module_abstract_from_file >;

use Exception::Class ();  # Must be after P::C::Exception::*

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw< generate_transformer_summary >;

#-----------------------------------------------------------------------------

sub generate_transformer_summary {

    print "\n\nGenerating Perl::ToPerl6::TransformerSummary.\n";


    my $configuration =
      Perl::ToPerl6::Config->new(-profile => $EMPTY, -necessity => 1, -theme => 'core');

    my @transformers = $configuration->all_transformers_enabled_or_not();
    my $transformer_summary = 'lib/Perl/ToPerl6/TransformerSummary.pod';

    open my $pod_file, '>', $transformer_summary
      or confess "Could not open $transformer_summary: $ERRNO";

    print {$pod_file} <<'END_HEADER';

=head1 NAME

Perl::ToPerl6::TransformerSummary - Descriptions of the Transformer modules included with L<Perl::ToPerl6|Perl::ToPerl6> itself.


=head1 DESCRIPTION

The following Transformer modules are distributed with Perl::ToPerl6. (There are
additional Transformers that can be found in add-on distributions.) Each
Transformer is listed here with its default necessity.  If you don't agree with
the default necessity, you can change it in your F<.perlmogrifyrc> file (try
C<perlmogrify --profile-proto> for a starting version).  See the documentation
of each module for its specific details.


=head1 POLICIES

END_HEADER


my $format = <<'END_TRANSFORMER';
=head2 L<%s|%s>

%s [Default necessity %d]

END_TRANSFORMER

eval {
    foreach my $transformer (@transformers) {
        my $module_abstract = $transformer->get_raw_abstract();

        printf
            {$pod_file}
            $format,
            $transformer->get_short_name(),
            $transformer->get_long_name(),
            $module_abstract || '',
            $transformer->default_necessity();
    }

    1;
}
    or do {
        # Yes, an assignment and not equality test.
        if (my $exception = $EVAL_ERROR) {
            if ( ref $exception ) {
                $exception->show_trace(1);
            }

            print {*STDERR} "$exception\n";
        }
        else {
            print {*STDERR} "Failed printing abstracts for an unknown reason.\n";
        }

        exit 1;
    };


print {$pod_file} <<'END_FOOTER';

=head1 VERSION

This is part of L<Perl::ToPerl6|Perl::ToPerl6> version 0.040


=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>


=head1 AUTHOR EMERITUS

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2015 Jeffrey Goff, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
END_FOOTER


    close $pod_file or confess "Could not close $transformer_summary: $ERRNO";

    print "Done.\n\n";

    return $transformer_summary;

}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::ToPerl6::TransformerSummaryGenerator - Create F<TransformerSummary.pod> file.


=head1 DESCRIPTION

This module contains subroutines for generating the
L<Perl::ToPerl6::TransformerSummary> POD file.  This file contains a brief
summary of all the Transformers that ship with L<Perl::ToPerl6>.  These
summaries are extracted from the C<NAME> section of the POD for each
Transformer module.

This library should be used at author-time to generate the
F<TransformerSummary.pod> file B<before> releasing a new distribution.  See
also the C<transformersummary> action in L<Perl::ToPerl6::Module::Build>.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<generate_transformer_summary()>

Generates the F<TransformerSummary.pod> file which contains a brief summary of all
the Transformers in this distro.  Returns the relative path this file.  Unlike
most of the other subroutines here, this subroutine should be used when
creating a distribution, not when building or installing an existing
distribution.

=back


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Imaginative Software Systems.  All rights reserved.

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
