#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use File::Path ();
use File::Spec;
use Getopt::Long;
use IPC::Run ();
use Net::SSH qw(ssh_cmd);
use URI;
use WordPress::Maintenance;
use WordPress::Maintenance::Config;
use WordPress::Maintenance::Directories;
use WordPress::Maintenance::RsyncTarget;


##
## Globals
##

my %DEFAULT_WORDPRESS_OPTIONS = (
    siteurl => '__URI__',
    home    => '__URI__',
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
    sync_database($config, $from, $to, $skip_uploads);

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
  -f, --from           The environment to sync from
  -t, --to             The environment to sync to
  -u, --skip-uploads   Skip synchronizing the wp-content/uploads directory
  -h, --help           Print this help screen and exit
END_OF_USAGE
}

sub sync_database {
    my ($config, $from, $to, $skip_uploads) = @_;

    my $from_config = $config->for_environment($from);
    my $to_config   = $config->for_environment($to);

    my $dump = dump_database($from_config);
    if ($from_config->{database}->{dump_encoding} ne $to_config->{database}->{dump_encoding}) {
        $dump = "SET NAMES $from_config->{database}->{dump_encoding};\n\n$dump";
    }

    print "Synchronizing uploads...\n";
    sync_uploads($from_config, $to_config) unless $skip_uploads;

    print "Loading database...\n";
    load_database($to_config, $dump);

    # Need direct connection for multisite setups
    print "Updating options...\n";

    my $to_dbh = $config->dbh($to);
    update_options($to_dbh, $to_config);
    $to_dbh->disconnect;
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

    # Speed up remote rsync by caching locally
    if ($from_target->is_remote) {
        my $tmp_target = _sync_remote_uploads($from_target);
        $from_target = $tmp_target;
    }

    # Ensure path exists at the destination
    run_command('mkdir', $to_config, [ '-p', File::Spec->join($to_config->{path}, @upload_path) ]);

    WordPress::Maintenance::copy($from_target, $to_target, [ @WordPress::Maintenance::DEFAULT_RSYNC_ARGS ]);
    WordPress::Maintenance::set_ownership($to_config->{path}, $to_config->{user}, $to_config->{group}, $to_config->{host});
}

# Sync remote uploads to a local directory, returning its location
sub _sync_remote_uploads {
    my ($from_target) = @_;

    my $path = $from_target->path;
    $path =~ s/\//_/g;

    my $tmp_path = File::Spec->join(File::Spec->tmpdir, $path);
    File::Path::make_path($tmp_path);
    chmod 0777, $tmp_path;

    my $tmp_target = WordPress::Maintenance::RsyncTarget->new({ path => $tmp_path });
    WordPress::Maintenance::copy($from_target, $tmp_target, [ @WordPress::Maintenance::DEFAULT_RSYNC_ARGS ]);

    return $tmp_target;
}

sub load_database {
    my ($config, $dump) = @_;

    run_mysql_command('mysql', $config, [], $dump);
}

sub update_options {
    my ($dbh, $config) = @_;

    my $uri = URI->new($config->{uri});

    my $table = $config->{database}->{table_prefix} . 'options';
    _update_options($dbh, $config, $table, $uri);

    # Update WordPress multisite paths if necessary
    if ($config->{wordpress}->{multisite}) {
        # Load the "from" domain and path to calculate "to" location
        my $site = _get_site($dbh, $config);

        _update_site($dbh, $config, $uri);
        _update_sitemeta($dbh, $config, $uri);
        _update_blogs($dbh, $config, $uri, $site->{path});
    }
}

sub _update_options {
    my ($dbh, $config, $table, $uri) = @_;

    my %options = (
        %DEFAULT_WORDPRESS_OPTIONS,
        %{ $config->{wordpress}->{options} || {} },
    );

    # WordPress doesn't like trailing slashes in siteurl and home
    $uri =~ s/\/$//;

    my $sth = $dbh->prepare("UPDATE $table SET option_value = ? WHERE option_name = ?")
        or die $dbh->errstr;

    foreach my $option_name (keys %options) {
        my $option_value = defined $options{$option_name}
            ? $options{$option_name}
            : '';
        $option_value =~ s/__URI__/$uri/g;

        $sth->execute($option_value, $option_name) or die $sth->errstr;
    }

    $sth->finish;
}

sub _get_site {
    my ($dbh, $config) = @_;

    my $table = $config->{database}->{table_prefix} . 'site';
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE id = ?")
        or die $dbh->errstr;

    $sth->execute($config->{wordpress}->{multisite}->{site_id});
    my $site = $sth->fetchrow_hashref;
    $sth->finish;

    return $site;
}

sub _update_site {
    my ($dbh, $config, $uri) = @_;

    my $table = $config->{database}->{table_prefix} . 'site';
    my $sth = $dbh->prepare("UPDATE $table SET domain = ?, path = ? WHERE id = ?")
        or die $dbh->errstr;

    $sth->execute($uri->host, $config->{base}, $config->{wordpress}->{multisite}->{site_id});
    $sth->finish;
}

sub _update_sitemeta {
    my ($dbh, $config, $uri) = @_;

    my $table = $config->{database}->{table_prefix} . 'sitemeta';
    my $sth = $dbh->prepare("UPDATE $table SET meta_value = ? WHERE site_id = ? AND meta_key = ?")
        or die $dbh->errstr;

    # WordPress multisite likes a trailing slash
    $uri .= '/' unless $uri =~ /\/$/;

    $sth->execute($uri, $config->{wordpress}->{multisite}->{site_id}, 'siteurl');
    $sth->finish;
}

sub _update_blogs {
    my ($dbh, $config, $uri, $base_path) = @_;

    my $table = $config->{database}->{table_prefix} . 'blogs';
    my $select_sth = $dbh->prepare("SELECT * FROM $table WHERE site_id = ?")
        or die $dbh->errstr;
    $select_sth->execute($config->{wordpress}->{multisite}->{site_id});

    my $update_sth = $dbh->prepare("UPDATE $table SET domain = ?, path = ? WHERE blog_id = ? AND site_id = ?")
        or die $dbh->errstr;

    while (my $row = $select_sth->fetchrow_hashref) {
        my $path = $row->{path};
        $path =~ s/^\Q$base_path\E/$config->{base}/;

        $update_sth->execute($uri->host, $path, $row->{blog_id}, $row->{site_id});

        # The default blog uses wp_options, so no need to update a separate table
        if ($row->{blog_id} != $config->{wordpress}->{multisite}->{blog_id}) {
            my $blog_uri = URI->new($path)->abs($uri);
            _update_blog_options($dbh, $config, $blog_uri, $row->{blog_id});
        }
    }

    $update_sth->finish;
    $select_sth->finish;
}

sub _update_blog_options {
    my ($dbh, $config, $uri, $blog_id) = @_;

    my $table = $config->{database}->{table_prefix} . $blog_id . '_options';
    _update_options($dbh, $config, $table, $uri);
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

    return run_local_command($command, \@args, $input);
}

sub run_command {
    my ($command, $config, $args, $input) = @_;

    my $output;
    if (my $host = $config->{host} and my $user = $config->{user}) {
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

    my $output;
    my $error;

    # XXX: Have seen Perl die with no message when e.g. the MySQL login is incorrect
    IPC::Run::run([ $command, @$args ], \$input, \$output, \$error)
        or croak "Error running [$command]: $?";

    return $output;
}
