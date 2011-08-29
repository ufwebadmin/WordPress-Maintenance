package WordPress::Maintenance;

use strict;
use warnings;

our $VERSION = '0.25_01';

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
