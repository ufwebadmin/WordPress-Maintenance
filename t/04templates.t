use strict;
use warnings;
use Carp;
use File::Find;
use File::Spec;
use FindBin;
use Template;
use Test::More 'no_plan';

use WordPress::Maintenance::Config;
use WordPress::Maintenance::Directories;

my $config = WordPress::Maintenance::Config->new(File::Spec->join($FindBin::Dir, 'site'));
my $template_directory = File::Spec->join($FindBin::Dir, File::Spec->updir, 'share');

my $tt = Template->new(
    INCLUDE_PATH => $template_directory,
    ABSOLUTE     => 1,
);

my $stash = {
    users => $config->users,
    %{ $config->for_environment('dev') },
};

# XXX: Refactor this and wp_deploy.pl's version
File::Find::find(sub {
    return if -d $File::Find::name;
    return if $File::Find::name =~ /~$/;
    return if $File::Find::dir =~ /\B\.svn\b/;
    return if $File::Find::dir =~ /\bmint\b/;

    my $output;
    ok($tt->process($File::Find::name, $stash, \$output), "successfully processed $File::Find::name");
}, $template_directory);
