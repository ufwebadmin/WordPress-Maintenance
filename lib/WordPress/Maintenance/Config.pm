package WordPress::Maintenance::Config;

use strict;
use warnings;
use Carp;
use File::Spec;
use Hash::Merge ();
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
