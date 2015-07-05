package Perl::Mogrify::Transformer::Files::FormatScript;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '0.01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{XXX FIXME XXX Insert 'use v6;' before the first line of a script};
Readonly::Scalar my $EXPL =>
    q{XXX FIXME XXX Insert 'use v6;' before the first line of a script};

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

sub _use_v6_statement {
    my $statement = PPI::Statement::Include->new;
        my $use = PPI::Token::Word->new('use');
        $statement->add_element( $use );
        my $ws = PPI::Token::Whitespace->new(' ');
        $statement->add_element( $ws );
        my $v6 = PPI::Token::Word->new('v6');
        $statement->add_element( $v6 );
        my $semicolon = PPI::Token::Structure->new(';');
        $statement->add_element( $semicolon );
    return $statement;
}

sub _use_Inline_Perl5_statement {
    my $statement = PPI::Statement::Include->new;
        my $use = PPI::Token::Word->new('use');
        $statement->add_element( $use );
        my $ws = PPI::Token::Whitespace->new(' ');
        $statement->add_element( $ws );
        my $inline_perl5 = PPI::Token::Word->new('Inline::Perl5');
        $statement->add_element( $inline_perl5 );
        my $semicolon = PPI::Token::Structure->new(';');
        $statement->add_element( $semicolon );
    return $statement;
}

sub transform {
    my ($self, $elem, $doc) = @_;
    my $modified;

    my $shebang = $doc->find_first(sub { $_[1]->isa('PPI::Token::Comment') and $_[1] =~ /^#!/ });
#    if ( $shebang ) {
#        $modified = 1;
##use Data::Dumper;die Dumper($shebang);
#        my $use_v6 = _use_v6_statement;
#        my $inline_perl5 = _use_Inline_Perl5_statement;
#        $shebang->top->insert_after($use_v6);# or die "Woops";
#        $shebang->top->insert_after($inline_perl5);# or die "Woops";
##use Data::Dumper;die Dumper($shebang);
#    }
$modified = 1;

    return $self->transformation( $DESC, $EXPL, $elem )
        if $modified;
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::CompoundStatements::FormatConditionals - Format if(), elsif(), unless()


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 conditionals still allow parentheses, but must have whitespace between C<if> and C<()>:

  if(1) { } --> if (1) { }
  if (1) { } --> if (1) { }

=head1 CONFIGURATION

This Transformer is not configurable except for the standard options.

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
