#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use Getopt::Long;
use URI;
use WordPress::Maintenance::Mechanize;


##
## Main script
##

main(@ARGV);
sub main {
    my $base_url;
    my $username;
    my $password;
    my $output_directory = File::Spec->curdir;
    my $output_filename;
    my $debug = 0;
    my $help = 0;
    die usage() unless GetOptions(
        'base|b=s'     => \$base_url,
        'username|u=s' => \$username,
        'password|p=s' => \$password,
        'output|o=s'   => \$output_directory,
        'filename|f=s' => \$output_filename,
        'debug|d'      => \$debug,
        'help|h'       => \$help,
    );
    print usage() and exit() if $help;
    die usage() unless $username and $password and $base_url;

    if ($base_url !~ m|^https?://|) {
        $base_url = 'http://' . $base_url;
    }

    my $url = URI->new($base_url);

    my $mech = WordPress::Maintenance::Mechanize->new({
        url   => $url,
        debug => $debug,
    });

    $mech->login($username, $password);

    unless ($output_filename) {
        $output_filename = $url;
        $output_filename =~ s|^https?://||;
        $output_filename =~ s|/$||;
        $output_filename =~ s|/|_|g;
    }

    my $output_file = File::Spec->join($output_directory, $output_filename . '.xml');
    $mech->export_site($output_file);
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -b, --base        The base WordPress URL, e.g. http://example.com/wordpress/
  -u, --username    The WordPress admin username
  -p, --password    The WordPress admin password
  -o, --output      The directory in which to store export files
                      (default: current directory)
  -f, --filename    The filename to use for the export file
                      (default: based on base WordPress URL)
  -h, --help        Print this help screen and exit

For the base WordPress URL, specify the location from which
wp-login.php, wp-admin, etc. can be accessed. Do not include anything
like wp-login.php after the main site URL. For multisite setups use
the site URL, not the network URL.
END_OF_USAGE
}
