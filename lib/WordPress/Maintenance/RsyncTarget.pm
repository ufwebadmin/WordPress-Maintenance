package WordPress::Maintenance::RsyncTarget;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use overload
    '""' => \&as_string,
    'eq' => \&equals,
    'ne' => \&not_equals;
use File::Spec;

__PACKAGE__->mk_accessors(qw/path user host/);

=head1 NAME

WordPress::Maintenance::RsyncTarget - Target for deployment

=head1 SYNOPSIS

    use WordPress::Maintenance::RsyncTarget;

    my $target = WordPress::Maintenance::RsyncTarget->new($config);
    print $target->is_remote;

=head1 DESCRIPTION

An C<rsync(1)> target for deploying a WordPress site.

=head1 METHODS

=head2 subdirectory

Return a new L<WordPress::Maintenance::RsyncTarget> corresponding to
the specified subdirectory of this target.

    $target->subdirectory(qw/wp-content uploads/);

=cut

sub subdirectory {
    my ($self, @path) = @_;

    my $path = File::Spec->join($self->path, @path);

    return WordPress::Maintenance::RsyncTarget->new({
        path => $path,
        user => $self->user,
        host => $self->host,
    });
}

=head2 is_remote

Return true iff this target is remote (i.e. it has a host part).

=cut

sub is_remote {
    my ($self) = @_;

    return $self->host ? 1 : 0;
}

=head2 as_string

From the configuration hash, return a string appropriate for use as an
C<rsync(1)> target.

=cut

sub as_string {
    my ($self) = @_;

    my $target = $self->path;
    if ($self->is_remote) {
        if (my $user = $self->user) {
            $target = $user . '@';
        }

        $target .= $self->host . ':' . $self->path;
    }

    return $target;
}

=head2 equals

Test whether this C<rsync(1)> target is the same as the specified
one. The object of the comparison can be a
L<WordPress::Maintenance::RsyncTarget> instance or a string.

=cut

sub equals {
    my ($self, $other) = @_;

    return $self->as_string eq $other;
}

=head2 not_equals

Test whether this C<rsync(1)> target is not the same as the specified
one. The object of the comparison can be a
L<WordPress::Maintenance::RsyncTarget> instance or a string.

=cut

sub not_equals {
    my ($self, $other) = @_;

    return $self->as_string ne $other;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
