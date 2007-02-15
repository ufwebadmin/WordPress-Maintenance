#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::Temp qw/tempdir/;
use URI;


##
## Globals
##

our $DEFAULT_WORDPRESS_URI = URI->new('http://wordpress.org/latest.tar.gz');


##
## Main script
##

main(@ARGV);
sub main {
    my ($wordpress_root, $wordpress_uri) = @_;

    die "$0 WORDPRESS_ROOT [WORDPRESS_URI]\n"
        unless $wordpress_root;

    $wordpress_uri ||= $DEFAULT_WORDPRESS_URI;

    my $src_directory = unwrap($wordpress_uri);

    my $src_wp_config   = File::Spec->join($src_directory, 'wp-config-sample.php');
    my $src_wp_content  = File::Spec->join($src_directory, 'wp-content');
    my $src_plugin_root = File::Spec->join($src_wp_content, 'plugins');
    my $src_theme_root  = File::Spec->join($src_wp_content, 'themes');

    my $wp_config   = File::Spec->join($wordpress_root, 'wp-config.php');
    my $htaccess    = File::Spec->join($wordpress_root, '.htaccess');
    my $wp_content  = File::Spec->join($wordpress_root, 'wp-content');
    my $plugin_root = File::Spec->join($wp_content, 'plugins');
    my $theme_root  = File::Spec->join($wp_content, 'themes');

    print "rsync -rvC --delete-after --exclude=$src_wp_config --exclude=$wp_config --exclude=$htaccess --exclude=$plugin_root --exclude=$theme_root\n";
}


##
## Subroutines
##

sub unwrap {
    my ($wordpress_uri) = @_;

    my $temp_directory = tempdir(CLEANUP => 1);

    print "Unpacking [$wordpress_uri] to [$temp_directory]...\n";
}
