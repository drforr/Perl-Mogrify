use 5.006001;

use strict;
use warnings;

use Module::Build 0.4200;
# meta_merge->resources->license now takes an arrayref of URLs in 0.4200 (or
# thereabouts, but I can't tell for sure from the Changes file).

use lib 'inc';

use Perl::ToPerl6::BuildUtilities qw<
    required_module_versions
    build_required_module_versions
    emit_tar_warning_if_necessary
>;
use Perl::ToPerl6::Module::Build;


emit_tar_warning_if_necessary();


my $builder = Perl::ToPerl6::Module::Build->new(
    module_name         => 'Perl::ToPerl6',
    dist_author         => 'Jeffrey Goff <drforr@pobox.com>',
    dist_abstract       => 'Convert Perl5 source to compile under Perl6.',
    license             => 'perl',
    dynamic_config      => 1,
    create_readme       => 1,
    create_packlist     => 1,
    sign                => 0,

    requires            => { required_module_versions() },
    build_requires      => { build_required_module_versions() },

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
