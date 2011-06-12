#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long;
use IO::Select;
use IPC::Open3;
use Net::SSH qw(ssh_cmd);
use POSIX qw(:sys_wait_h);
use URI;
use WordPress::Maintenance;
use WordPress::Maintenance::Config;
use WordPress::Maintenance::Directories;
use WordPress::Maintenance::RsyncTarget;


##
## Globals
##

my %DEFAULT_WORDPRESS_OPTIONS = (
    siteurl                        => '__URI__',
    home                           => '__URI__',
    http_authentication_logout_uri => '__URI__/Shibboleth.sso/Logout?return=__URI__/',
);


##
## Main script
##

main(@ARGV);
sub main {
    my $source_directory = File::Spec->curdir;
    my $from             = 'prod';
    my $to               = 'dev';
    my $skip_uploads     = 0;
    my $help             = 0;
    die usage() unless GetOptions(
        'source|src|s=s'   => \$source_directory,
        'from|f=s'         => \$from,
        'to|t=s'           => \$to,
        'skip-uploads|u=s' => \$skip_uploads,
        'help|h'           => \$help,
    );
    print usage() and exit() if $help;

    my $config = WordPress::Maintenance::Config->new($source_directory);
    sync_database($config->for_environment($from), $config->for_environment($to), $skip_uploads);
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
  -u, --skip-uploads   Skip synchronizing the wp-content/uploads directory
  -h, --help           Print this help screen and exit
END_OF_USAGE
}

sub sync_database {
    my ($from_config, $to_config, $skip_uploads) = @_;

    my $dump = dump_database($from_config);
    if ($from_config->{database}->{dump_encoding} ne $to_config->{database}->{dump_encoding}) {
        $dump = "SET NAMES $from_config->{database}->{dump_encoding};\n\n$dump";
    }

    sync_uploads($from_config, $to_config) unless $skip_uploads;
    load_database($to_config, $dump);
    update_options($to_config);
}

sub dump_database {
    my ($config) = @_;

    my $output = run_mysql_command('mysqldump', $config, [ '--add-drop-table', '--extended-insert' ]);

    return $output;
}

sub sync_uploads {
    my ($from_config, $to_config) = @_;

    _sync_uploads($from_config, $to_config, $WordPress::Maintenance::Directories::UPLOADS);

    if ($from_config->{wordpress}->{multisite}) {
        _sync_uploads($from_config, $to_config, $WordPress::Maintenance::Directories::UPLOAD_BLOGS);
    }
}

sub _sync_uploads {
    my ($from_config, $to_config, $directory) = @_;

    my @upload_path = ($WordPress::Maintenance::Directories::CONTENT, $directory);

    my $from_target = WordPress::Maintenance::RsyncTarget->new($from_config);
    $from_target = $from_target->subdirectory(@upload_path);

    my $to_target = WordPress::Maintenance::RsyncTarget->new($to_config);
    $to_target = $to_target->subdirectory(@upload_path);

    # Handle remote-to-remote rsync
    if ($from_target->is_remote and $to_target->is_remote) {
        my $tmp_path = tempdir(CLEANUP => 1);

        my $tmp_target = WordPress::Maintenance::RsyncTarget->new({ path => $tmp_path });
        WordPress::Maintenance::copy($from_target, $tmp_target, [ @WordPress::Maintenance::DEFAULT_RSYNC_ARGS ]);

        $from_target = $tmp_target;
    }

    # Ensure path exists at the destination
    run_command('mkdir', $to_config, [ '-p', File::Spec->join($to_config->{path}, @upload_path) ]);

    WordPress::Maintenance::copy($from_target, $to_target, [ @WordPress::Maintenance::DEFAULT_RSYNC_ARGS ]);
    WordPress::Maintenance::set_ownership($to_config->{path}, $to_config->{user}, $to_config->{group}, $to_config->{host});
}

sub load_database {
    my ($config, $dump) = @_;

    run_mysql_command('mysql', $config, [], $dump);
}

sub update_options {
    my ($config) = @_;

    my %options = (
        %DEFAULT_WORDPRESS_OPTIONS,
        %{ $config->{wordpress}->{options} || {} },
    );

    # WordPress doesn't like trailing slashes
    my $uri = URI->new($config->{uri});
    $uri =~ s/\/$//;

    my $options = '';
    foreach my $option_name (keys %options) {
        my $option_value = defined $options{$option_name}
            ? $options{$option_name}
            : '';
        $option_value =~ s/__URI__/$uri/g;

        $options .= "UPDATE wp_options SET option_value = '$option_value' WHERE option_name = '$option_name';\n";
    }

    run_mysql_command('mysql', $config, [], $options);
}

sub run_mysql_command {
    my ($command, $config, $args, $input) = @_;

    my @args;
    foreach my $option (qw/host port user password/) {
        push @args, "--${option}=" . $config->{database}->{$option}
            if $config->{database}->{$option};
    }
    push @args, @$args if ref $args and ref $args eq 'ARRAY';
    push @args, $config->{database}->{name};

    # XXX: Special case for mysql.osg.ufl.edu, to which the MySQL client on nersp cannot connect
    my $force_local_command = 0;
    if ($config->{database}->{host} and $config->{database}->{host} eq 'mysql.osg.ufl.edu') {
        $force_local_command = 1;
    }

    return run_command($command, $config, \@args, $input, $force_local_command);
}

sub run_command {
    my ($command, $config, $args, $input, $force_local_command) = @_;

    my $database_host = $config->{database}->{host};

    my $output;
    if (my $host = $config->{host} and my $user = $config->{user} and not $force_local_command) {
        $output = run_remote_comamnd($user, $host, $command, $args, $input);
    }
    else {
        $output = run_local_command($command, $args, $input);
    }

    return $output;
}

sub run_remote_comamnd {
    my ($user, $host, $command, $args, $input) = @_;

    my $output = ssh_cmd({
        user         => $user,
        host         => $host,
        command      => $command,
        args         => $args,
        stdin_string => $input,
    });

    return $output;
}

sub run_local_command {
    my ($command, $args, $input) = @_;

    $args ||= [];

    my $in  = IO::File->new;
    my $out = IO::File->new;
    my $err = IO::File->new;

    my $pid = open3($in, $out, $err, $command, @$args);
    print $in $input if defined $input;
    close $in;

    my $select = IO::Select->new;
    $select->add($_) for $out, $err;

    my $output = '';
    my $error  = '';
    while ($select->count) {
        my @handles = $select->can_read;
        foreach my $handle (@handles) {
            my $buffer = '';
            my $bytes = sysread($handle, $buffer, 4096);

            unless (defined($bytes)) {
                waitpid $pid, WNOHANG;
                die $!;
            }

            $select->remove($handle) unless $bytes;
            if ($handle eq $out) {
                $output .= $buffer;
            }
            elsif ($handle eq $err) {
                $error .= $buffer;
            }
        }
    }

    waitpid $pid, 0;
    if ($error) {
        croak $error;
    }

    return $output;
}
