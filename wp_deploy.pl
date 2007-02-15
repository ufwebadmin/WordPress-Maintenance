#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use File::Find ();
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Getopt::Long;
use Template;
use YAML ();

use lib File::Spec->join($FindBin::Bin, 'lib');
use WordPress::Executables;


##
## Globals
##

our @DEFAULT_RSYNC_ARGS = qw(
    --archive
    --verbose
    --compress
    --delete-after
);
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
    my $source_directory = File::Spec->curdir;
    my $environment = 'dev';
    my $template_directory = File::Spec->join($FindBin::Bin, 'templates');
    my $checkout = 0;
    die usage() unless GetOptions(
        'source|src|s=s'      => \$source_directory,
        'environment|env|e=s' => \$environment,
        'templates|t=s'       => \$template_directory,
        'checkout|C'          => \$checkout,
    );

    die "Directory ($template_directory) does not exist"
        unless -d $template_directory;

    my $config_file = File::Spec->join($source_directory, 'config.yml');
    my $users_file = File::Spec->join($source_directory, 'users.txt');
    my $www_directory = File::Spec->join($source_directory, 'www');
    die "Source ($source_directory) does not appear to be WordPress site checkout\n"
        unless -f $config_file and -f $users_file and -d $www_directory;

    my $config = YAML::LoadFile($config_file);
    my @users = split /\s+/, slurp($users_file);

    croak "No configuration for '$environment' environment"
        unless $config->{$environment};

    my $stage_directory = tempdir(CLEANUP => 1);
    stage($www_directory, $config->{$environment}, \@users, $template_directory, $stage_directory, $checkout);
    deploy($stage_directory, $config->{$environment});
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
  -C, --checkout       Keep svn checkout data when deploying
END_OF_USAGE
}

sub stage {
    my ($www_directory, $config, $users, $template_directory, $stage_directory, $checkout) = @_;

    stage_wordpress($www_directory, $stage_directory, $checkout);
    stage_configuration($config, $users, $template_directory, $stage_directory);

    if (my $shebang = $config->{shebang}) {
        my @executables = map { File::Spec->join($stage_directory, $_) } @WordPress::Executables::ALL;
        add_shebang($shebang, \@executables);
        make_executable(\@executables);
    }

    # TODO: Fix permissions on wp-content and subdirectories
    my $wp_content_directory = File::Spec->join($stage_directory, 'wp-content');

    # Add plugin directories
    # TODO: Refactor
    for (qw(wp-cache uf-url-cache)) {
        my $directory = File::Spec->join($wp_content_directory, $_);
        mkdir $directory;
        if ($config->{group} and not $config->{username}) {
            system('chgrp', $config->{group}, $directory);
            chmod 0771, $directory;
        }
    }

    # Add wp-cache symbolic link
    # TODO: Refactor
    my $cwd = Cwd::getcwd();
    chdir $wp_content_directory;
    symlink
        File::Spec->join('plugins', 'wp-cache', 'wp-cache-phase1.php'),
        'advanced-cache.php';
    chdir $cwd;

    # Add robots.txt if requested
    # TODO: Refactor
    if ($config->{exclude_robots}) {
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

    my @args = @DEFAULT_RSYNC_ARGS;
    push @args, ('--exclude', $_) for @excludes;

    copy($www_directory, $stage_directory, \@args);
}

sub stage_configuration {
    my ($config, $users, $template_directory, $stage_directory) = @_;

    my $tt = Template->new(
        INCLUDE_PATH => $template_directory,
        ABSOLUTE     => 1,
    );

    my $stash = {
        users => $users,
        %{ $config },
    };

    my @files;
    File::Find::find(sub {
        return if -d $File::Find::name;
        return if $File::Find::dir =~ /\.svn/;

        push @files, $File::Find::name;
    }, $template_directory);

    foreach my $file (@files) {
        my $relative = File::Spec->abs2rel($file, $template_directory);
        my $final = File::Spec->join($stage_directory, $relative);
        $tt->process($file, $stash, $final) or croak $tt->error . "\n";
    }
}

sub add_shebang {
    my ($shebang, $executables) = @_;

    foreach my $executable (@$executables) {
        next unless -f $executable;

        my $content = slurp($executable);

        # Add the shebang
        open my $fh, '>', $executable or die "Error opening $executable: $!";
        print $fh $shebang, "\n", $content;
        close $fh;
    }
}

sub make_executable {
    my ($executables) = @_;

    chmod 0755, grep { -f } @$executables;
}

sub deploy {
    my ($stage_directory, $config) = @_;

    my $target = $config->{path};
    if (my $hostname = $config->{hostname} and my $username = $config->{username}) {
        $target = $username . '@' . $hostname . ':' . $target;
    }

    copy($stage_directory, $target, \@DEFAULT_RSYNC_ARGS);
    set_ownership($config);
}

# Fix ownership for suEXEC
sub set_ownership {
    my ($config) = @_;

    if (my $path = $config->{path}
      and my $hostname = $config->{hostname}
      and my $username = $config->{username}
      and my $group = $config->{group}) {
        system('ssh', $hostname, '-l', $username, 'find', $path, '-print0', '|', 'xargs', '-0', 'chown', "$username:$group");
    }
}

sub slurp {
    my ($filename) = @_;

    open my $fh, '<', $filename or croak "Error opening $filename: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;
}

sub copy {
    my ($sources, $destination, $args) = @_;

    my $ref = ref $sources;
    $sources = [ $sources ] unless $ref and $ref eq 'ARRAY';

    my @args = (
        @$args,
        map { "$_/" } @$sources, $destination,
    );

    system('rsync', @args);
}
