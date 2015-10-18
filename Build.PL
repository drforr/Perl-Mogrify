use 5.006001;

use strict;
use warnings;

use Module::Build 0.4200;
# meta_merge->resources->license now takes an arrayref of URLs in 0.4200 (or
# thereabouts, but I can't tell for sure from the Changes file).

use lib 'inc';

use Perl::ToPerl6::Module::Build;


my $builder = Perl::ToPerl6::Module::Build->new(
    module_name         => 'Perl::ToPerl6',
    dist_author         => 'Jeffrey Goff <drforr@pobox.com>',
    dist_abstract       => 'Convert Perl5 source to compile under Perl6.',
    license             => 'perl',
    dynamic_config      => 1,
    create_readme       => 1,
    create_packlist     => 1,
    sign                => 0,

    requires            => {
        'B::Keywords'           => '0',
#        'Carp'                  => '0', # In core
        'Config::Tiny'          => '0',
#        'Cwd'                   => '0', # In core
#        'English'               => '0', # In core
        'Exception::Class'      => '0',
        'Exporter'              => '0',
#        'File::Basename'        => '0', # In core
#        'File::Find'            => '0', # In core
#        'File::Path'            => '0', # In core
#        'File::Spec'            => '0', # In core
#        'File::Spec::Functions' => '0', # In core
#        'File::Spec::Unix'      => '0', # In core
#        'File::Temp'            => '0', # In core
        'IO::String'            => '0',
        'Module::Build'         => '0',
        'Pod::PlainText'        => '0',
#        'Pod::Select'           => '0', # In core
#        'Scalar::Util'          => '0', # In core
#        'Getopt::Long'          => '0', # In core
#        'Pod::Usage'            => '0', # In core
        'PPI'                   => '0',
        'PPIx::Regexp'          => '0',
        'PPIx::Utilities'       => '0',
        'Readonly'              => '0',
        'String::Format'        => '0',
        'Text::Balanced'        => '0',
        'YAML'                  => '0',
        'Test::Builder'         => '0',
        'Test::Deep'            => '0',
        'Test::More'            => '0',
    },
    build_requires      => {
    },

    # Don't require a developer version of Module::Build, even if the
    # distribution tarball was created with one.  (Oops.)
    configure_requires  => {
        'Module::Build' => '0.4024',
    },

    script_files        => ['bin/perlmogrify'],

    meta_merge          => {
        resources => {
            bugtracker  => 'https://github.com/drforr/Perl-ToPerl6/issues',
            license     => [ 'http://dev.perl.org/licenses' ],
            repository  => 'git://github.com/drforr/Perl-ToPerl6.git',
        },
        no_index        => {
            file        => [
                qw<
                    TODO.pod
                >
            ],
            directory   => [
                qw<
                    doc
                    inc
                    tools
                >
            ],
        },
        x_authority => 'cpan:JGOFF',
    },

    add_to_cleanup      => [
        qw<
            Debian_CPANTS.txt
            Makefile
            Makefile.old
            MANIFEST.bak
            META.json
            META.yml
            pm_to_blib
            README
        >,
    ],
);

$builder->create_build_script();


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
