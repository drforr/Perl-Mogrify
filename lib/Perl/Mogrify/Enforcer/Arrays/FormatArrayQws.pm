package Perl::Mogrify::Enforcer::Arrays::FormatArrayQws;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Enforcer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{qw(a b) in perl5 is now qw (a b) due to whitespace rules};
Readonly::Scalar my $EXPL =>
    q{Format qw(...) to qw (...)};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    return ! $document->is_module();
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    my $modified;

    #
    # Can't declare a variable $qw ... Teehee.
    #
    my $Qws = $doc->find('PPI::Token::QuoteLike::Words');
    if ( $Qws ) {
        for my $Qw ( @{ $Qws } ) {
            next unless $Qw->content =~ /^qw\(/;
            $modified = 1;
            my $old_content = $Qw->content;

            $old_content =~ s{^qw\(}{^qw (};

            $Qw->set_content( $old_content );
        }
    }

    return $self->violation( $DESC, $EXPL, $elem )
        if $modified;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Enforcer::Array::FormatArrayQws - Format qw() to qw ()


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 qw() operates almost exactly like Perl5 qw() but with one corner case - C<qw(a b c)> is treated as a function all. This Enforcer adds a single space in order to clear this problem up:

  qw(a b c) --> qw (a b c)
  qw{a b c} --> qw{a b c}

=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.

=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 2015 Jeffrey Goff

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

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
