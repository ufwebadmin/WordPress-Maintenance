package WordPress::Maintenance::Config;

use strict;
use warnings;
use Carp;
use File::Spec;
use Hash::Merge ();
use URI;
use YAML ();

our $DEFAULT_CONFIG_FILENAME = 'config.yml';
our $DEFAULT_CONFIG = {
    allow_comments => 0,
    wordpress => {
        wp_cache => {
            use_flock =>        0,
            acceptable_files => [ 'wp-atom.php', 'wp-comments-popup.php', 'wp-commentsrss2.php', 'wp-links-opml.php', 'wp-locations.php', 'wp-rdf.php', 'wp-rss.php', 'wp-rss2.php' ],
            rejected_uris    => [ 'wp-' ],
        },
    },
    database => {
        dump_encoding => 'utf8',
    },
};
our $DEFAULT_MERGE = 1;
our $DEFAULT_USERS_FILENAME = 'users.txt';

=head1 NAME

WordPress::Maintenance::Config - Load configuration for a WordPress instance

=head1 SYNOPSIS

    use WordPress::Maintenance::Config;

    my $config = WordPress::Maintenance::Config->new;
    my $environment_config = $config->for_environment('dev');
    my $users = $config->users;

=head1 DESCRIPTION

Automatically load configuration for a WordPress site.

=head1 EXAMPLE CONFIGURATION

For a given site directory, the configuration is typically located in
a file named C<config.yml>.  For example:

    --- #YAML:1.0
    # Do not use tabs for indentation or label/value separation!
    dev:
      path:           /var/www/dev.example.com/htdocs
      uri:            https://dev.example.com
      base:           /news/
      exclude_robots: 1
      wordpress:
        multisite: 0
        wp_cache:
          enabled: 0
        options:
      database:
        host:          mysql.example.com
        user:          dev
        password:      p4ssw0rd
        name:          dev

    test:
      host:           test.example.com
      path:           /nerdc/www/test.example.com/htdocs
      uri:            http://test.example.com
      base:           /
      exclude_robots: 1
      wordpress:
        multisite: 0
        wp_cache:
          enabled: 0
        options:
      database:
        host:          mysql.example.com
        port:          3307
        user:          news
        password:      p4ssw0rd
        name:          news

    prod:
      host:           prod.example.com
      path:           /nerdc/www/prod.example.com/htdocs
      uri:            http://prod.example.com
      base:           /
      exclude_robots: 0
      wordpress:
        multisite: 0
        wp_cache:
          enabled: 0
        options:
      database:
        host:          mysql.example.com
        port:          3306
        user:          news
        password:      p4ssw0rd
        name:          news

Other parameters are supported; see the configuration templates
distributed with this library for details on what goes where in
WordPress.

=head1 METHODS

=head2 new

Load the WordPress configuration from the specified directory.

Optionally, you can specify the configuration filename, the user list
filename, and whether or not to merge the default configuration with
the one loaded from the configuration file.

=cut

sub new {
    my ($class, $directory, $config_filename, $users_filename, $merge) = @_;

    $directory       ||= File::Spec->curdir;
    $config_filename ||= $DEFAULT_CONFIG_FILENAME;
    $users_filename  ||= $DEFAULT_USERS_FILENAME;
    $merge = defined $merge ? $merge : $DEFAULT_MERGE;

    my $config = $class->_load_config($directory, $config_filename, $merge);
    my $users  = $class->_load_users($directory, $users_filename);

    my $self = {
        config => $config,
        users  => $users,
    };
    bless $self, ref $class || $class;

    return $self;
}

=head2 _load_config

(Private) Load the configuration file and return the data as a
hashref.

=cut

sub _load_config {
    my ($self, $directory, $filename, $merge) = @_;

    my $config_file = File::Spec->join($directory, $filename);
    croak "No configuration file found ($config_file)"
        unless -f $config_file;

    my $config = YAML::LoadFile($config_file);

    if ($merge) {
        foreach my $environment (keys %$config) {
            $config->{$environment} = Hash::Merge::merge($config->{$environment}, $DEFAULT_CONFIG);

            my $uri = URI->new($config->{$environment}->{uri});
            $config->{$environment}->{uri} = $uri;
        }
    }

    return $config;
}

=head2 _load_users

(Private) Load the list of users and return it as an arrayref.

=cut

sub _load_users {
    my ($class, $directory, $filename) = @_;

    my $users_file = File::Spec->join($directory, $filename);
    croak "No users file found ($users_file)"
        unless -f $users_file;

    open my $fh, '<', $users_file or croak $!;
    my @users = split /\s+/, do { local $/; <$fh> };
    close $fh;

    return \@users;
}

=head2 for_environment

Return the configuration for the specified environment.

=cut

sub for_environment {
    my ($self, $environment) = @_;

    croak "Could not find configuration for environment [$environment]"
        unless exists $self->{config}->{$environment};

    return $self->{config}->{$environment};
}

=head2 users

Return the list of users for the current configuration.

=cut

sub users {
    my ($self) = @_;

    return $self->{users};
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
