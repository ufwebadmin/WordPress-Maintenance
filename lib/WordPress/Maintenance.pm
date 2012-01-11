package WordPress::Maintenance;

use strict;
use warnings;

our $VERSION = '0.31';

our @DEFAULT_RSYNC_ARGS = qw(
    --archive
    --compress
    --delete
    --no-perms
    --no-group
    --chmod=ugo=rwX
);

=head1 NAME

WordPress::Maintenance - Configuration and file maintenance for WordPress instances

=head1 DESCRIPTION

A collection of scripts for maintaining WordPress instances in a
high-availablity environment.  Via a configuration file, a WordPress
instance can be deployed with a single command.

=head1 INSTALLATION

To install L<WordPress::Maintenance> and its related scripts, download
the latest package from:

https://github.com/ufwebadmin/WordPress-Maintenance/downloads

Then unpack the file and run the installer:

    cd WordPress-Maintenance
    perl Makefile.PL
    make test
    make install

=head1 GETTING STARTED

All of the scripts work based on a local copy of the WordPress files
and a configuration file. This allows you to your WordPress
setup in a version control system, including references to the
appropriate version of WordPress and any plugins. For example, you
might have a Subversion repository containing the following:

    wordpress_site_name/
        config.yml
        overlay/
        www/
            [...]
            wp-content/
                [...]
                plugins/
                    http-authentication/

The C<overlay> directory can contain configuration templates that
override those provided by this package. Use this, for example, to
provide a custom C<.htaccess> file.

The C<www> directory can be configured using C<svn:externals> to
automatically check out the required WordPress components.

For an example configuration file, see
L<WordPress::Maintenance::Config>.

=head1 COMMON TASKS

Once you've set up your local copy of the WordPress site and the
related configuration file, you're ready to start deploying and
synchronizing it.

=head2 DEPLOYING

Assuming your C<config.yml> file is configured with C<dev>, C<test>,
and C<prod> stages, deploying to these is simple:

    wp_deploy.pl -e dev
    wp_deploy.pl -e test
    wp_deploy.pl -e prod

For more information on the options that C<wp_deploy.pl> provides, run
the following:

    wp_deploy.pl --help

=head2 SYNCHRONIZING DATABASES

Eventually you'll need to copy real data from one stage to
another. For example, you may need to load everything from C<prod> in
to C<dev> so that you, the developer, can work with real data.  To do
so:

    wp_sync_database.pl -f prod -t dev
    wp_sync_database.pl -f prod -t test

For more information on the options that C<wp_sync_database.pl>
provides, run the following:

    wp_sync_database.pl --help

=head1 METHODS

=head2 copy

Copy from the specified directory to the specified target using
C<rsync(1)>.

=cut

sub copy {
    my ($sources, $destination, $args) = @_;

    my $ref = ref $sources;
    $sources = [ $sources ] unless $ref and $ref eq 'ARRAY';

    my @args = (
        @{ $args || [] },
        map { "$_/" } @$sources, $destination,
    );

    system('rsync', @args);
}

=head2 set_ownership

Set the ownership - locally or remotely - for the WordPress instance.

=cut

sub set_ownership {
    my ($path, $user, $group, $host) = @_;

    return unless $group;

    my @cmd = ('chgrp', '-R', '-f', $group);
    if ($user) {
        @cmd = ('chown', '-R', '-f', "$user:$group");
    }

    push @cmd, $path;

    if ($host) {
        unshift @cmd, 'ssh', $host, '-l', $user;
    }

    system(@cmd);
}

=head1 SEE ALSO

=over 4

=item * L<WordPress::Maintenance::Config>

=item * L<WordPress::Maintenance::Directories>

=item * L<WordPress::Maintenance::Executables>

=back

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
