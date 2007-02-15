package WordPress::Directories;

use strict;
use warnings;
use File::Spec;

our $ADMIN = 'wp-admin';
our $CONTENT = 'wp-content';
our $INCLUDES = 'wp-includes';

our @PLUGIN = qw(
    uf-url-cache
    wp-cache
);

our @ALL = (
    $ADMIN,
    $CONTENT,
    $INCLUDES,
    map { File::Spec->join($CONTENT, $_) } @PLUGIN,
);

=head1 NAME

WordPress::Directories - List files which WordPress needs to execute

=head1 SYNOPSIS

    use WordPres::Directories;

    # Just those required by plugins in the default UF WordPress install
    print join ', ', @WordPress::Directories::PLUGIN;

    # Just wp-admin, wp-content, and wp-includes
    print $WordPress::Directories::ADMIN;
    print $WordPress::Directories::CONTENT;
    print $WordPress::Directories::INCLUDES;

    # All of the above
    print join ', ', @WordPress::Directories::ALL;

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
