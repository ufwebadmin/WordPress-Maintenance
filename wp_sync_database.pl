#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Spec;
use File::Temp qw(tempfile);
use Getopt::Long;
use YAML ();


##
## Main script
##

main(@ARGV);
sub main {
    my $source_directory = File::Spec->curdir;
    my $from = 'prod';
    my $to = 'dev';
    die usage() unless GetOptions(
        'source|src|s=s' => \$source_directory,
        'from|f=s'       => \$from,
        'to|t=s'         => \$to,
    );

    my $config_file = File::Spec->join($source_directory, 'config.yml');

    my $config = YAML::LoadFile($config_file);
    foreach my $environment ($from, $to) {
        croak "No configuration for '$environment' environment"
            unless $config->{$environment};
    }

    sync_database($config->{$from}, $config->{$to});
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -s, --source         The path to the site SVN checkout
  -f, --from           The environment to sync from
  -t, --to             The environment to sync to
END_OF_USAGE
}

sub sync_database {
    my ($from_config, $to_config) = @_;

    my $dump_file = dump_database($from_config);
    load_database($to_config, $dump_file);
}

sub dump_database {
    my ($config) = @_;

    my ($fh, $dump_file) = tempfile(UNLINK => 1);

    my @args = (
        'mysqldump',
        '--host=' . $config->{database}->{hostname},
        '--user=' . $config->{database}->{username},
        '--password=' . $config->{database}->{password},
        '--add-drop-table',
        '--extended-insert',
        $config->{database}->{name},
        "> $dump_file",
    );

    if (my $hostname = $config->{hostname} and my $username = $config->{username}) {
        unshift @args, 'ssh', $hostname, '-l', $username;
    }

    print Dumper \@args;

    return $dump_file;
}

sub load_database {
    my ($config, $dump_file) = @_;

    my @args = (
        'mysql',
        '--host=' . $config->{database}->{hostname},
        '--user=' . $config->{database}->{username},
        '--password=' . $config->{database}->{password},
        "< $dump_file",
    );

    if (my $hostname = $config->{hostname} and my $username = $config->{username}) {
        unshift @args, 'ssh', $hostname, '-l', $username;
    }

    print Dumper \@args;
}
