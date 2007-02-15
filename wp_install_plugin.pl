#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use URI;


##
## Globals
##

our $DEFAULT_SVN_REPO = URI->new('svn+ssh://dev.webadmin.ufl.edu/var/svn/wordpress/plugins');


##
## Main script
##

main(@ARGV);
sub main {
    my ($plugin_uri, $wordpress_root) = @_;

    die "$0 PLUGIN_URL WORDPRESS_ROOT\n"
        unless $plugin_uri and $wordpress_root;

    if ($plugin_uri !~ /:\/\//) {
        my $plugin_name = $plugin_uri;

        $plugin_uri = $DEFAULT_SVN_REPO->clone;
        $plugin_uri->path_segments($plugin_uri->path_segments, $plugin_name, 'trunk');
    }

    my $plugin_root = File::Spec->join($wordpress_root, 'wp-content', 'plugins');
    die "Plugin directory [$plugin_root] is not writable\n"
        unless -d $plugin_root;

    my $plugin_directory = File::Spec->join($plugin_root, basename(dirname($plugin_uri->path)));
    if (-d $plugin_directory) {
        my $old_plugin_directory = "$plugin_directory.old";
        warn "Plugin directory exists; renaming to [$old_plugin_directory]\n";
        die "Old plugin directory exists; cannot continue\n"
            if -d $old_plugin_directory;
        rename $plugin_directory, $old_plugin_directory;
    }

    print "Exporting [$plugin_uri] to [$plugin_directory]...\n";
    system('svn', 'export', $plugin_uri, $plugin_directory);
}
