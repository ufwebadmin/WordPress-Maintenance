package WordPress::Maintenance::Directories;

use strict;
use warnings;
use File::Spec;

our $ADMIN = 'wp-admin';
our $CONTENT = 'wp-content';
our $INCLUDES = 'wp-includes';
our $UPLOADS = 'uploads';
our $UPLOAD_BLOGS = 'blogs.dir';

our @PLUGIN = qw(
    uf-url-cache
);

our @WRITABLE = (
    map { File::Spec->join($CONTENT, $_) } (@PLUGIN, $UPLOADS, $UPLOAD_BLOGS),
);

our @ALL = (
    $ADMIN,
    $CONTENT,
    $INCLUDES,
    @WRITABLE,
);

=head1 NAME

WordPress::Maintenance::Directories - List WordPress-related directories

=head1 SYNOPSIS

    use WordPress::Maintenance::Directories;

    # Just those required by plugins in the default UF WordPress install
    print join ', ', @WordPress::Maintenance::Directories::PLUGIN;

    # Just wp-admin, wp-content, and wp-includes
    print $WordPress::Maintenance::Directories::ADMIN;
    print $WordPress::Maintenance::Directories::CONTENT;
    print $WordPress::Maintenance::Directories::INCLUDES;

    # All of the above that need to be writable by the Web server
    print join ', ', @WordPress::Maintenance::Directories::WRITABLE;

    # All of the above
    print join ', ', @WordPress::Maintenance::Directories::ALL;

=head1 DESCRIPTION

Stores a list of WordPress directories, notably those that require
special permissions.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
