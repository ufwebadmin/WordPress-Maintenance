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
    my $site;
    my $username;
    my $password;
    my $output_directory = File::Spec->curdir;
    my $help             = 0;
    die usage() unless GetOptions(
        'base|b=s'     => \$base_url,
        'site|s=s'     => \$site,
        'username|u=s' => \$username,
        'password|p=s' => \$password,
        'output|o=s'   => \$output_directory,
        'help|h'       => \$help,
    );
    print usage() and exit() if $help;
    die usage() unless $username and $password and $base_url;

    my $path = $site || '/';
    my $name = $site || 'default';

    my $url = URI->new($base_url);
    $url->path($path);

    my $mech = WordPress::Maintenance::Mechanize->new({ url => $url });
    $mech->login($username, $password);

    my $filename = File::Spec->join($output_directory, $name . '.xml');
    $mech->export_site($filename);
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]... < list_of_site_names.txt

Available options:
  -b, --base        The base WordPress URL
  -u, --username    The WordPress admin username
  -p, --password    The WordPress admin password
  -o, --output      The directory in which to store export files
  -h, --help        Print this help screen and exit
END_OF_USAGE
}
