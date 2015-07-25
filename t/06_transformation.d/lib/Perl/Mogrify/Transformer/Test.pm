package Perl::ToPerl6::Transformer::Test;

use 5.006001;
use strict;
use warnings;

use Perl::ToPerl6::Utils qw{ :severities };
use base 'Perl::ToPerl6::Transformer';

sub default_severity { return $SEVERITY_LOWEST }
sub applies_to { return 'PPI::Token::Word' }

sub transform {
    my ( $self, $elem, undef ) = @_;
    return $self->transformation( 'desc', 'expl', $elem );
}

1;
__END__

=head1 DESCRIPTION

diagnostic

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
