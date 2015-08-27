package Perl::ToPerl6::Statistics;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

#-----------------------------------------------------------------------------

our $VERSION = '0.03';

#-----------------------------------------------------------------------------

sub new {
    my ( $class ) = @_;

    my $self = bless {}, $class;

    $self->{_modules} = 0;
    $self->{_subs} = 0;
    $self->{_statements} = 0;
    $self->{_lines} = 0;
    $self->{_lines_of_blank} = 0;
    $self->{_lines_of_comment} = 0;
    $self->{_lines_of_data} = 0;
    $self->{_lines_of_perl} = 0;
    $self->{_lines_of_pod} = 0;
    $self->{_transformations_by_transformer} = {};
    $self->{_transformations_by_necessity} = {};
    $self->{_total_transformations} = 0;

    return $self;
}

#-----------------------------------------------------------------------------

sub accumulate {
    my ($self, $doc, $transformations) = @_;

    $self->{_modules}++;

    my $subs = $doc->find('PPI::Statement::Sub');
    if ($subs) {
        foreach my $sub ( @{$subs} ) {
            $self->{_subs}++;
        }
    }

    my $statements = $doc->find('PPI::Statement');
    $self->{_statements} += $statements ? scalar @{$statements} : 0;

    my @lines = split /$INPUT_RECORD_SEPARATOR/, $doc->serialize();
    ## use mogrify
    $self->{_lines} += scalar @lines;
    {
        my ( $in_data, $in_pod );
        foreach ( @lines ) {
            if ( q{=} eq substr $_, 0, 1 ) {
                $in_pod = not m/ \A \s* =cut \b /smx;
                $self->{_lines_of_pod}++;
            } elsif ( $in_pod ) {
                $self->{_lines_of_pod}++;
            } elsif ( q{__END__} eq $_ || q{__DATA__} eq $_ ) {
                $in_data = 1;
                $self->{_lines_of_perl}++;
            } elsif ( $in_data ) {
                $self->{_lines_of_data}++;
            } elsif ( m/ \A \s* \# /smx ) {
                $self->{_lines_of_comment}++;
            } elsif ( m/ \A \s* \z /smx ) {
                $self->{_lines_of_blank}++;
            } else {
                $self->{_lines_of_perl}++;
            }
        }
    }

    foreach my $transformation ( @{ $transformations } ) {
        $self->{_transformations_by_necessity}->{ $transformation->necessity() }++;
        $self->{_transformations_by_transformer}->{ $transformation->transformer() }++;
        $self->{_total_transformations}++;
    }

    return;
}

#-----------------------------------------------------------------------------

sub modules {
    my ( $self ) = @_;

    return $self->{_modules};
}

#-----------------------------------------------------------------------------

sub subs {
    my ( $self ) = @_;

    return $self->{_subs};
}

#-----------------------------------------------------------------------------

sub statements {
    my ( $self ) = @_;

    return $self->{_statements};
}

#-----------------------------------------------------------------------------

sub lines {
    my ( $self ) = @_;

    return $self->{_lines};
}

#-----------------------------------------------------------------------------

sub lines_of_blank {
    my ( $self ) = @_;

    return $self->{_lines_of_blank};
}

#-----------------------------------------------------------------------------

sub lines_of_comment {
    my ( $self ) = @_;

    return $self->{_lines_of_comment};
}

#-----------------------------------------------------------------------------

sub lines_of_data {
    my ( $self ) = @_;

    return $self->{_lines_of_data};
}

#-----------------------------------------------------------------------------

sub lines_of_perl {
    my ( $self ) = @_;

    return $self->{_lines_of_perl};
}

#-----------------------------------------------------------------------------

sub lines_of_pod {
    my ( $self ) = @_;

    return $self->{_lines_of_pod};
}

#-----------------------------------------------------------------------------

sub transformations_by_necessity {
    my ( $self ) = @_;

    return $self->{_transformations_by_necessity};
}

#-----------------------------------------------------------------------------

sub transformations_by_transformer {
    my ( $self ) = @_;

    return $self->{_transformations_by_transformer};
}

#-----------------------------------------------------------------------------

sub total_transformations {
    my ( $self ) = @_;

    return $self->{_total_transformations};
}

#-----------------------------------------------------------------------------

sub statements_other_than_subs {
    my ( $self ) = @_;

    return $self->statements() - $self->subs();
}

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------

sub transformations_per_file {
    my ( $self ) = @_;

    return if $self->modules() == 0;

    return $self->total_transformations() / $self->modules();
}

#-----------------------------------------------------------------------------

sub transformations_per_statement {
    my ( $self ) = @_;

    my $statements = $self->statements_other_than_subs();

    return if $statements == 0;

    return $self->total_transformations() / $statements;
}

#-----------------------------------------------------------------------------

sub transformations_per_line_of_code {
    my ( $self ) = @_;

    return if $self->lines() == 0;

    return $self->total_transformations() / $self->lines();
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::ToPerl6::Statistics - Compile stats on Perl::ToPerl6 transformations.


=head1 DESCRIPTION

This class accumulates statistics on Perl::ToPerl6 transformations across one or
more files.  NOTE: This class is experimental and subject to change.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 METHODS

=over

=item C<new()>

Create a new instance of Perl::ToPerl6::Statistics.  No arguments are supported
at this time.


=item C< accumulate( $doc, \@transformations ) >

Accumulates statistics about the C<$doc> and the C<@transformations> that were
found.


=item C<modules()>

The number of chunks of code (usually files) that have been analyzed.


=item C<subs()>

The total number of subroutines analyzed by this ToPerl6.


=item C<statements()>

The total number of statements analyzed by this ToPerl6.


=item C<lines()>

The total number of lines of code analyzed by this ToPerl6.


=item C<lines_of_blank()>

The total number of blank lines analyzed by this ToPerl6. This includes only
blank lines in code, not POD or data.


=item C<lines_of_comment()>

The total number of comment lines analyzed by this ToPerl6. This includes only
lines whose first non-whitespace character is C<#>.


=item C<lines_of_data()>

The total number of lines of data section analyzed by this ToPerl6, not
counting the C<__END__> or C<__DATA__> line. POD in a data section is counted
as POD, not data.


=item C<lines_of_perl()>

The total number of lines of Perl code analyzed by this ToPerl6. Perl appearing
in the data section is not counted.


=item C<lines_of_pod()>

The total number of lines of POD analyzed by this ToPerl6. Pod occurring in a
data section is counted as POD, not as data.


=item C<transformations_by_necessity()>

The number of transformations of each necessity found by this ToPerl6 as a
reference to a hash keyed by necessity.


=item C<transformations_by_transformer()>

The number of transformations of each transformer found by this ToPerl6 as a
reference to a hash keyed by full transformer name.


=item C<total_transformations()>

The total number of transformations found by this ToPerl6.


=item C<statements_other_than_subs()>

The total number of statements minus the number of subroutines.
Useful because a subroutine is considered a statement by PPI.


=item C<transformations_per_file()>

The total transformations divided by the number of modules.


=item C<transformations_per_statement()>

The total transformations divided by the number statements minus
subroutines.


=item C<transformations_per_line_of_code()>

The total transformations divided by the lines of code.


=back


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


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
