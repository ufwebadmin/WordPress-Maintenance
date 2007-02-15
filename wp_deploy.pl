#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Find;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Getopt::Long;
use Template;
use YAML ();


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
    .svn/
    /license.txt
    /readme.html
    /wp-config-sample.php
);
our @DEFAULT_EXECUTABLES = qw(
    index.php
    wp-atom.php
    wp-comments-post.php
    wp-commentsrss2.php
    wp-feed.php
    wp-links-opml.php
    wp-login.php
    wp-mail.php
    wp-pass.php
    wp-rdf.php
    wp-register.php
    wp-rss2.php
    wp-rss.php
    wp-trackback.php
    xmlrpc.php
);
push @DEFAULT_EXECUTABLES, map { File::Spec->join('wp-admin', $_) } qw(
    bookmarklet.php
    categories.php
    cat-js.php
    edit-comments.php
    edit-form-ajax-cat.php
    edit-pages.php
    edit.php
    import.php
    index.php
    inline-uploading.php
    install-helper.php
    install.php
    link-add.php
    link-categories.php
    link-import.php
    link-manager.php
    list-manipulation.php
    moderation.php
    options-discussion.php
    options-general.php
    options-misc.php
    options-permalink.php
    options.php
    options-reading.php
    options-writing.php
    page-new.php
    plugin-editor.php
    plugins.php
    post.php
    profile.php
    profile-update.php
    setup-config.php
    sidebar.php
    templates.php
    theme-editor.php
    themes.php
    update-links.php
    upgrade.php
    user-edit.php
    users.php
);


##
## Main script
##

main(@ARGV);
sub main {
    my $source_directory = File::Spec->curdir;
    my $environment = 'dev';
    my $template_directory = File::Spec->join($FindBin::Bin, 'templates');
    die usage() unless GetOptions(
        'source|src|s=s'      => \$source_directory,
        'environment|env|e=s' => \$environment,
        'templates|t=s'       => \$template_directory,
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

    my $stage_directory = tempdir(CLEANUP => 0);

    stage($www_directory, $template_directory, $config, \@users, $environment, $stage_directory);
#    deploy($stage_directory, $destination);
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
END_OF_USAGE
}

sub stage {
    my ($www_directory, $template_directory, $config, $users, $environment, $stage_directory) = @_;

    $config = $config->{$environment};
    croak "No configuration for '$environment' environment"
        unless $config;

    stage_wordpress($www_directory, $stage_directory);
    stage_configuration($config, $users, $template_directory, $stage_directory);

    if (my $shebang = $config->{shebang}) {
        my @executables = map { File::Spec->join($stage_directory, $_) } @DEFAULT_EXECUTABLES;
        add_shebang($shebang, \@executables);
        make_executable(\@executables);
    }

    # TODO: Add plugin directories
    # TODO: Add wp-cache symbolic link
}

sub stage_wordpress {
    my ($www_directory, $stage_directory) = @_;

    my @excludes = @DEFAULT_RSYNC_EXCLUDES;

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
    find(sub {
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
        print $fh $shebang . "\n" . $content;
        close $fh;
    }
}

sub make_executable {
    my ($executables) = @_;

    chmod 0755, grep { -f } @$executables;
}

sub deploy {
    my ($stage_directory, $destination) = @_;

    copy($stage_directory, $destination, \@DEFAULT_RSYNC_ARGS);
    # TODO: suEXEC
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
