#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use File::Find ();
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long;
use Template;
use WordPress::Maintenance;
use WordPress::Maintenance::Config;
use WordPress::Maintenance::Directories;
use WordPress::Maintenance::Executables;
use WordPress::Maintenance::RsyncTarget;


##
## Globals
##

our @DEFAULT_RSYNC_EXCLUDES = qw(
    /license.txt
    /readme.html
    /wp-config-sample.php
);


##
## Main script
##

main(@ARGV);
sub main {
    my $source_directory   = File::Spec->curdir;
    my $environment        = 'dev';
    my $template_directory = dist_dir('WordPress-Maintenance');
    my $checkout           = 0;
    my $cleanup            = 1;
    my $help               = 0;
    die usage() unless GetOptions(
        'source|src|s=s'      => \$source_directory,
        'environment|env|e=s' => \$environment,
        'templates|t=s'       => \$template_directory,
        'checkout|C'          => \$checkout,
        'cleanup'             => \$cleanup,
        'help|h'              => \$help,
    );
    print usage() and exit() if $help;

    die "Directory ($template_directory) does not exist"
        unless -d $template_directory;

    my $www_directory = File::Spec->join($source_directory, 'www');
    die "Source ($source_directory) does not appear to be WordPress site checkout\n"
        unless -d $www_directory and -d File::Spec->join($www_directory, $WordPress::Maintenance::Directories::CONTENT);

    my $config = WordPress::Maintenance::Config->new($source_directory);

    my $stage_directory = tempdir(CLEANUP => $cleanup);

    print "Staging WordPress...\n";
    stage($www_directory, $config, $environment, $template_directory, $stage_directory, $checkout);

    print "Deploying from stage...\n";
    deploy($stage_directory, $config, $environment);

    print "Done.\n";
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -s, --source         The path to the site SVN checkout
  -e, --environment    The environment to deploy (dev, test, prod)
  -t, --templates      The path to the directory containing configuration file
                       templates
  -C, --checkout       Keep SVN checkout data when deploying
      --cleanup        Clean up temporary directory after deploying
                       (default: on)
  -h, --help           Print this help screen and exit
END_OF_USAGE
}

sub stage {
    my ($www_directory, $config, $environment, $template_directory, $stage_directory, $checkout) = @_;

    my $environment_config = $config->for_environment($environment);

    stage_wordpress($www_directory, $stage_directory, $checkout);
    stage_configuration($config, $environment, $template_directory, $stage_directory);

    if (my $shebang = $environment_config->{shebang}) {
        my @executables = map { File::Spec->join($stage_directory, $_) } @WordPress::Maintenance::Executables::ALL;
        add_shebang($shebang, \@executables);
        make_executable(\@executables);
    }

    # Add writable directories; ownership handled post-deploy for permissions
    for (@WordPress::Maintenance::Directories::WRITABLE) {
        my $directory = File::Spec->join($stage_directory, $_);
        mkdir $directory;
    }

    # Add wp-cache symbolic link
    my $wp_content_directory = File::Spec->join($stage_directory, $WordPress::Maintenance::Directories::CONTENT);

    my $cwd = Cwd::getcwd();
    chdir $wp_content_directory;
    symlink
        File::Spec->join('plugins', 'wp-cache', 'wp-cache-phase1.php'),
        'advanced-cache.php';
    chdir $cwd;

    # Add robots.txt if requested
    if ($environment_config->{exclude_robots}) {
        open my $fh, '>', File::Spec->join($stage_directory, 'robots.txt') or die $!;
        print $fh "User-agent: *\nDisallow: /\n";
        close $fh;
    }
}

sub stage_wordpress {
    my ($www_directory, $stage_directory, $checkout) = @_;

    my @excludes = @DEFAULT_RSYNC_EXCLUDES;
    unless ($checkout) {
        push @excludes, '.svn/';
    }

    my @args = @WordPress::Maintenance::DEFAULT_RSYNC_ARGS;
    push @args, ('--exclude', $_) for @excludes;

    WordPress::Maintenance::copy($www_directory, $stage_directory, \@args);
}

sub stage_configuration {
    my ($config, $environment, $template_directory, $stage_directory) = @_;

    my $tt = Template->new(
        INCLUDE_PATH => $template_directory,
        ABSOLUTE     => 1,
    );

    my $stash = {
        users => $config->users,
        keys  => $config->keys,
        salts => $config->salts,
        %{ $config->for_environment($environment) },
    };

    File::Find::find(sub {
        return if -d $File::Find::name;
        return if $File::Find::dir =~ /\B\.svn\b/;

        my $relative = File::Spec->abs2rel($File::Find::name, $template_directory);
        my $final = File::Spec->join($stage_directory, $relative);
        $tt->process($File::Find::name, $stash, $final) or croak $tt->error . "\n";
    }, $template_directory);
}

sub add_shebang {
    my ($shebang, $executables) = @_;

    foreach my $executable (@$executables) {
        next unless -f $executable;

        my $fh;

        open $fh, '<', $executable or croak "Error opening $executable: $!";
        my $content = do { local $/; <$fh> };
        close $fh;

        open $fh, '>', $executable or die "Error opening $executable: $!";
        print $fh $shebang, "\n", $content;
        close $fh;
    }
}

sub make_executable {
    my ($executables) = @_;

    # suEXEC at OSG requires 0755
    chmod 0755, grep { -f } @$executables;
}

sub deploy {
    my ($stage_directory, $config, $environment) = @_;

    my $environment_config = $config->for_environment($environment);
    my $target = WordPress::Maintenance::RsyncTarget->new($environment_config);

    my @args = @WordPress::Maintenance::DEFAULT_RSYNC_ARGS;
    push @args, map {
        ("--filter", "P /$_/*")
    } @WordPress::Maintenance::Directories::WRITABLE;

    WordPress::Maintenance::copy($stage_directory, $target, \@args);
    WordPress::Maintenance::set_ownership($environment_config->{path}, $environment_config->{user}, $environment_config->{group}, $environment_config->{host});

    if (my $server_group = $environment_config->{server_group}) {
        for (@WordPress::Maintenance::Directories::WRITABLE) {
            my $directory = File::Spec->join($environment_config->{path}, $_);
            WordPress::Maintenance::set_ownership($directory, $environment_config->{user}, $server_group, $environment_config->{host});
        }
    }
}
