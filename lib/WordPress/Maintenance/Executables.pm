package WordPress::Maintenance::Executables;

use strict;
use warnings;
use File::Spec;
use WordPress::Maintenance::Directories;

our @ROOT = qw(
    index.php
    wp-comments-post.php
    wp-links-opml.php
    wp-login.php
    wp-mail.php
    wp-pass.php
    wp-register.php
    xmlrpc.php
);

our @INCLUDES = (
    File::Spec->join(qw/js tinymce tiny_mce_gzip.php/),
);

our @ADMIN = qw(
    bookmarklet.php
    categories.php
    cat-js.php
    edit-comments.php
    edit-form-ajax-cat.php
    edit-pages.php
    edit.php
    execute-pings.php
    import.php
    index.php
    inline-uploading.php
    install-helper.php
    install.php
    link-add.php
    link-categories.php
    link-import.php
    link-manager.php
    list-manipulation.php
    moderation.php
    options-discussion.php
    options-general.php
    options-misc.php
    options-permalink.php
    options.php
    options-reading.php
    options-writing.php
    page-new.php
    plugin-editor.php
    plugins.php
    post.php
    profile.php
    profile-update.php
    setup-config.php
    sidebar.php
    templates.php
    theme-editor.php
    themes.php
    update-links.php
    upgrade.php
    user-edit.php
    users.php
);

our @MINT = (
    'index.php',
    File::Spec->join(qw/pepper colbymakowsky sparks sparks.php/),
);

our @ALL = (
    @ROOT,
    (map { File::Spec->join($WordPress::Maintenance::Directories::INCLUDES, $_) } @INCLUDES),
    (map { File::Spec->join($WordPress::Maintenance::Directories::ADMIN, $_) } @ADMIN),
    (map { File::Spec->join($WordPress::Maintenance::Directories::MINT, $_) } @MINT),
);

=head1 NAME

WordPress::Maintenance::Executables - List WordPress-related files which need execute bits

=head1 SYNOPSIS

    use WordPress::Maintenance::Executables;

    # Just those in the WordPress root
    print join ', ', @WordPress::Maintenance::Executables::ROOT;

    # Just those in wp-includes
    print join ', ', @WordPress::Maintenance::Executables::INCLUDES;

    # Just those in wp-admin
    print join ', ', @WordPress::Maintenance::Executables::ADMIN;

    # Just those in mint
    print join ', ', @WordPress::Maintenance::Executables::MINT;

    # All of the above (those in e.g. wp-admin have appropriate
    # directory prepended)
    print join ', ', @WordPress::Maintenance::Executables::ALL;

=head1 DESCRIPTION

Stores a list of WordPress executables, i.e. files that require a
shebang in a CGI environment.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
