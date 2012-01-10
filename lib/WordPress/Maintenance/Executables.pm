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
    File::Spec->join(qw/js tinymce wp-mce-help.php/),
    File::Spec->join(qw/js tinymce wp-tinymce.php/),
);

our @ADMIN = qw(
    admin-ajax.php
    bookmarklet.php
    cat-js.php
    categories.php
    edit-comments.php
    edit-form-ajax-cat.php
    edit-pages.php
    edit-tags.php
    edit.php
    execute-pings.php
    export.php
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
    load-scripts.php
    load-styles.php
    media-new.php
    media-upload.php
    media.php
    moderation.php
    nav-menus.php
    options-discussion.php
    options-general.php
    options-media.php
    options-misc.php
    options-permalink.php
    options-privacy.php
    options-reading.php
    options-writing.php
    options.php
    page-new.php
    plugin-editor.php
    plugin-install.php
    plugins.php
    post-new.php
    post.php
    profile-update.php
    profile.php
    setup-config.php
    sidebar.php
    templates.php
    theme-editor.php
    themes.php
    tools.php
    update-core.php
    update-links.php
    upgrade.php
    upload.php
    user-edit.php
    user-new.php
    users.php
    widgets.php
);

our @ALL = (
    @ROOT,
    (map { File::Spec->join($WordPress::Maintenance::Directories::INCLUDES, $_) } @INCLUDES),
    (map { File::Spec->join($WordPress::Maintenance::Directories::ADMIN, $_) } @ADMIN),
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
