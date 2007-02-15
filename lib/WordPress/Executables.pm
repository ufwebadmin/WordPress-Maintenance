package WordPress::Executables;

use strict;
use warnings;
use File::Spec;

our @ROOT = qw(
    index.php
    wp-atom.php
    wp-comments-post.php
    wp-commentsrss2.php
    wp-feed.php
    wp-links-opml.php
    wp-login.php
    wp-mail.php
    wp-pass.php
    wp-rdf.php
    wp-register.php
    wp-rss2.php
    wp-rss.php
    wp-trackback.php
    xmlrpc.php
);

our @ADMIN = qw(
    bookmarklet.php
    categories.php
    cat-js.php
    edit-comments.php
    edit-form-ajax-cat.php
    edit-pages.php
    edit.php
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

our @ALL = (
    @ROOT,
    map { File::Spec->join('wp-admin', $_) } @ADMIN,
);

=head1 NAME

WordPress::Executables - List files which WordPress needs to execute

=head1 SYNOPSIS

    use WordPres::Executables;

    # Just those in the WordPress root
    print join ', ', @WordPress::Executables::ROOT;

    # Just those in wp-admin
    print join ', ', @WordPress::Executables::ADMIN;

    # All of the above (those in e.g. wp-admin have appropriate
    # directory prepended)
    print join ', ', @WordPress::Executables::ALL;

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
