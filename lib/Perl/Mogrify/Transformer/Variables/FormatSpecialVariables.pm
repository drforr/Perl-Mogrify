package Perl::Mogrify::Transformer::Variables::FormatSpecialVariables;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Mogrify::Utils qw{ :characters :severities };

use base 'Perl::Mogrify::Transformer';

our $VERSION = '1.125';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Transform @ARGV to @*ARGS};
Readonly::Scalar my $EXPL => q{Perl6 changes many special variables};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Token::Symbol' }

#-----------------------------------------------------------------------------

my %map = (
    'STDIN'            => '$*IN',
    'STDOUT'           => '$*OUT',
    'STDERR'           => '$*ERR',
    '$ARG'             => '$_',
    #$_[1],$_[2].. => $^a,$^b # Say whaa?
    #'$a' => -, # XXX Needs some work
    #- => '$/',
#    '$1'     => '$0', # And so on,  make sure they don't get modified twice
#    '$2'     => '$1',
#    '$3'     => '$2',
#    '$4'     => '$1',
    '$`'               => '$/.prematch',
    '$PREMATCH'        => '$/.prematch',
    '${^PREMATCH}'     => '$/.prematch',
    '$&'               => '~$/',
    '$MATCH'           => '~$/',
    '${^MATCH}'        => '~$/',
    '$\''              => '$/.postmatch',
    '$POSTMATCH'       => '$/.postmatch',
    '${^POSTMATCH}'    => '$/.postmatch',
    '$+'               => '$/[$/.end]', # Ouch?
    '$^N'              => '$/[*-1]', # Likewise.
    '@+'               => '(map {.from},$/[*])',
    '@-'               => '(map {.to},$/[*])',
    #'@-' # $-[0] => $0.from, ergo $-[$n] = $/[$n].from # XXX special
    #'@+' # $+[0] => $0.to, ergo $+[$n] = $/[$n].to # XXX special
    '$.'               => '$*IN.ins()',
    '$NR'              => '$*IN.ins()',
    '$/'               => '$*IN.input-line-separator()',
    '$RS'              => '$*IN.input-line-separator()',
    '$!'               => '$*OUT.autoflush()', # xxx May need some work
    '$,'               => '$*OUT.output-field-separator()',
    '$OFS'             => '$*OUT.output-field-separator()',
    '$\\'              => '$*OUT.output-record-separator()',
    '$$'               => '$*PID',
    '$PID'             => '$*PID',
    '$('               => '$*GID',
    '$GID'             => '$*GID',
    '$<'               => '$*UID',
    '$UID'             => '$*UID',
    '$>'               => '$*EUID',
    '$EUID'            => '$*EUID',
    '$)'               => '$*EGID',
    '$GID'             => '$*EGID',
    '$0'               => '$*PROGRAM-NAME',
    '$PROGRAM_NAME'    => '$*PROGRAM-NAME',
    '$^C'              => '$*COMPILING',
    '$COMPILING'       => '$*COMPILING',
    '$^D'              => '$*DEBUGGING',
    '$DEBUGGING'       => '$*DEBUGGING',
    '$^F'              => '$*SYS_FD_MAX', # XXX ?
    '$SYS_FD_MAX'      => '$*SYS_FD_MAX', # XXX ?
    '$^I'              => '$*INPLACE_EDIT', # XXX ?
    '$INPLACE_EDIT'    => '$*INPLACE_EDIT', # XXX ?
    '$^M'              => '$*EMERGENCY_MEMORY', # XXX ?
    '$^O'              => '$*KERNEL.name',
    '$^OSNAME'         => '$*KERNEL.name',
    '$^P'              => '$*PERLDB',
    '$PERLDB'          => '$*PERLDB',
    '$^R'              => '$*LAST_REGEXP_CODE_RESULT', # XXX ?
    '$^T'              => '$*INITTIME', # Temporal::Instant
    '$BASETIME'        => '$*INITTIME', # Temporal::Instant
    '$^V'              => '$?PERL.version',
    '$]'               => '$?PERL.version',
    '$^W'              => '$*WARNINGS',
    '${^WARNING_BITS}' => '$*WARNINGS',
    '$^X'              => '$?COMPILER',
    'ARGV'             => '$*ARGFILES',
# $*ARGFILES     Note the P6 idiom for this handle:
#                for lines() {
#                  # each time through loop
#                  # proc a line from files named in ARGS
#                }
    '@ARGV'            => '@*ARGS', # XXX Remember $ARGV[...]
#    'ARGVOUT'           # XXX ?
#    '$ARGV'           # XXX ?
    '@F'               => '@_', # XXX May require translation?
    '%ENV'             => '%*ENV', # XXX remember $ENV{...}
    '@INC'             => '@*INC', # XXX remember $INC[...]
    '$SIG{__WARN__}'   => '$*ON_WARN', # XXX Note it's not the actual %SIG
    '$SIG{__DIE__}'    => '$*ON_DIE', # XXX Note it's not the actual %SIG
);

# Keep track of these because they might be useful notes.
my %all_new = (
    '$!' => 1, # current exception
);

my %eliminated = (
    '%!'              => 1, # Don't forget $!{...}
    '$['              => 1,
    '$*'              => 1,
    '$#'              => 1, # XXX Don't confuse with $#a
    '$^H'             => 1, # Yipes?
    '%^H'             => 1, # Yipes?
                  
    '$!'              => 1, # => $! maybe
    '$ERRNO'          => 1, # => $! maybe
    '$OS_ERROR'       => 1, # => $! maybe
    '$?'              => 1, # => $! maybe
    '$CHILD_ERROR'    => 1, # => $! maybe
    '$@'              => 1, # => $! maybe
    '$^E'             => 1,
    '$^S'             => 1,
    '$"'              => 1,
    '$LIST_SEPARATOR' => 1,
    '$;'              => 1,
    '$SUBSEP'         => 1,
    '%INC'            => 1, # XXX This is in a CompUnitRepo, whatever that is.
    '%SIG'            => 1, # XXX Different than the manpage -  event filters plus exception translation
    '${^OPEN}'        => 1, # Supposedly internal-only.
);

#
# @ARGV --> @*ARGS
# $1    --> $0 and so on.
#
sub transform {
    my ($self, $elem, $doc) = @_;

    my $old_content = $elem->content;
    return unless exists $map{$old_content};

    if ( exists $map{$old_content} ) {
        my $new_content = $map{$old_content};

        $elem->set_content( $new_content );
    }
    elsif ( $old_content =~ /^\$(\d+)$/ ) {
        my $new_content = '$' . $1 - 1;
   
        $elem->set_content( $new_content );
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Mogrify::Transformer::Variables::FormatSpecialVariables - Format special variables such as @ARGV


=head1 AFFILIATION

This Transformer is part of the core L<Perl::Mogrify|Perl::Mogrify>
distribution.


=head1 DESCRIPTION

Perl6 renames many special variables, this changes most of the common variable names, including replacing some of the more obscure variables with new Perl6 equivalent code:

  @ARGV --> @*ARGS
  @+    --> (map {.from},$/[*])

Other variables are no longer used in Perl6, but will not be removed as likely they have expressions attached to them. These cases will probably be dealt with by adding comments to the expression.

Transforms special variables outside of comments, heredocs, strings and POD.

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