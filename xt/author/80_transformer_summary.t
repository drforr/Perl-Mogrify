#!perl

use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

use File::Spec;
use List::MoreUtils qw(any);

use Perl::Mogrify::TransformerFactory ( -test => 1 );
use Perl::Mogrify::TestUtils qw{ bundled_policy_names };

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

my $summary_file =
    File::Spec->catfile( qw< lib Perl Mogrify PolicySummary.pod > );
if (open my ($fh), '<', $summary_file) {

    my $content = do {local $INPUT_RECORD_SEPARATOR=undef; <$fh> };
    close $fh or confess "Couldn't close $summary_file: $OS_ERROR";

    my @policy_names = bundled_policy_names();
    my @summaries    = $content =~ m/^=head2 [ ]+ L<[\w:]+[|]([\w:]+)>/gxms;
    plan( tests => 2 + 2 * @policy_names );

    my %num_summaries;
    for my $summary (@summaries) {
        ++$num_summaries{$summary};
    }
    if (!ok(@summaries == keys %num_summaries, 'right number of summaries')) {
        for my $policy_name (sort keys %num_summaries) {
            next if 1 == $num_summaries{$policy_name};
            diag('Duplicate summary for ' . $policy_name);
        }
    }

    my $profile = Perl::Mogrify::UserProfile->new();
    my $factory = Perl::Mogrify::TransformerFactory->new( -profile => $profile );
    my %found_transformers = map { ref $_ => $_ } $factory->create_all_transformers();

    my %descriptions = $content =~ m/^=head2 [ ]+ L<[\w:]+[|]([\w:]+)>\n\n([^\n]+)/gxms;
    for my $policy_name (keys %descriptions) {
        my $severity;
        if (
            $descriptions{$policy_name} =~ s/ [ ] \[ Default [ ] severity [ ] (\d+) \] //xms
        ) {
            $severity = $1;
        }
        else {
            $severity = '<unknown>';
        }

        $descriptions{$policy_name} = {
            desc => $descriptions{$policy_name},
            severity => $severity,
        };
    }

    for my $policy_name ( @policy_names ) {
        my $label = qq{PolicySummary.pod has "$policy_name"};
        my $has_summary = delete $num_summaries{$policy_name};
        is( $has_summary, 1, $label );

        my $summary_severity = $descriptions{$policy_name}->{severity};
        my $real_severity = $found_transformers{$policy_name} &&
          $found_transformers{$policy_name}->default_severity;
        is( $summary_severity, $real_severity, "severity for $policy_name" );
    }

    if (!ok(0 == keys %num_summaries, 'no extra summaries')) {
        for my $policy_name (sort keys %num_summaries) {
            diag('Extraneous summary for ' . $policy_name);
        }
    }
}
else {
    plan 'no_plan';
    fail qq<Cannot open "$summary_file": $ERRNO>;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/80_policysummary.t.without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
