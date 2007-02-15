#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long;


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
our $DEFAULT_SHEBANG  = '#!/usr/local/bin/php';
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
    my ($source, $destination, $environment, $checkout, $shebang);
    die usage() unless GetOptions(
        'source|src|s=s'       => \$source,
        'destination|dest|d=s' => \$destination,
        'environment|env|e=s'  => \$environment,
        'checkout|C'           => \$checkout,
        'shebang|S'            => \$shebang,
    );
    die "Please provide a source, destination, and environment\n"
        unless $source and $destination and $environment;

    my $www = File::Spec->join($source, 'www');
    my $etc = File::Spec->join($source, 'etc');
    die "Source ($source) does not appear to be WordPress site checkout\n"
        unless -d $www and -d $etc;

    my $configuration = File::Spec->join($etc, $environment);
    die "Environment ($environment) configuration not found in source ($source)"
        unless -d $configuration;

    my $stage = tempdir(CLEANUP => 1);
    stage($www, $configuration, $stage, $checkout);
    if ($shebang) {
        my @executables = @DEFAULT_EXECUTABLES;
        add_shebang($DEFAULT_SHEBANG, \@executables, $stage);
        make_executable(\@executables, $stage);
        # TODO: How to handle suexec?
    }
    deploy($stage, $destination);
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -s, --source         The path to the site SVN checkout
  -d, --destination    The destination path or rsync target
  -e, --environment    The environment to deploy (dev, test, prod)
  -C, --checkout       Keep svn checkout data when deploying
  -S, --shebang        Add a shebang line to the top of PHP files (where necessary)
END_OF_USAGE
}

sub stage {
    my ($www, $configuration, $stage, $checkout) = @_;

    my @excludes = @DEFAULT_RSYNC_EXCLUDES;
    if ($checkout) {
        # Don't overwrite the checkout files from $www
        push @excludes, File::Spec->join($configuration, '.svn/');
        push @excludes, File::Spec->join($configuration, '**', '.svn/');
    }
    else {
        push @excludes, '--exclude', '.svn/';
    }

    my @args = @DEFAULT_RSYNC_ARGS;
    push @args, ('--exclude', $_) for @excludes;

    _copy([ $www, $configuration ], $stage, \@args);
}

sub add_shebang {
    my ($shebang, $executables, $directory) = @_;

    foreach my $executable (@$executables) {
        $executable = File::Spec->join($directory, $executable);
        next unless -f $executable;

        my $fh;

        # Slurp the contents
        open $fh, '<', $executable or die "Error opening $executable: $!";
        my $content = do { local $/; <$fh> };
        close $fh;

        # Add the shebang
        open $fh, '>', $executable or die "Error opening $executable: $!";
        print $fh, $shebang, "\n", $content;
        close $fh;
    }
}

# TODO
sub make_executable {
    my ($executables, $directory) = @_;
}

sub deploy {
    my ($stage, $destination) = @_;

    _copy($stage, $destination, \@DEFAULT_RSYNC_ARGS);
    # TODO: Add plugin directories (wp-cache and uf-url-cache) and symbolic link (wp-cache)
}

sub _copy {
    my ($sources, $destination, $args) = @_;

    my $ref = ref $sources;
    $sources = [ $sources ] unless $ref and $ref eq 'ARRAY';

    my @args = (
        @$args,
        map { "$_/" } @$sources, $destination,
    );

    system('rsync', @args);
}
