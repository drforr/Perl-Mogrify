package TransformationTest2;

use 5.006001;
use strict;
use warnings;

use PPI::Document;
use Perl::ToPerl6::Transformation;

# This file exists solely to test Perl::ToPerl6::Transformation::import()

sub get_violation {

    my $code = 'Hello World;';
    my $doc = PPI::Document->new(\$code);
    return Perl::ToPerl6::Transformation->new('', '', [0,0], 0);
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
