package WordPress::Maintenance::Mechanize;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Carp qw/croak/;
use HTML::TreeBuilder;
use URI;
use WWW::Mechanize;

__PACKAGE__->mk_accessors(qw/url mech debug/);

=head1 NAME

WordPress::Maintenance::RsyncTarget - Target for deployment

=head1 SYNOPSIS

    use WordPress::Maintenance::Mechanize;

    my $mech = WordPress::Maintenance::Mechanize->new({ url => 'http://example.com/wordpress' });
    $mech->login('username', 'password');

=head1 DESCRIPTION

Automate operations like logging in to a WordPress instance.

=head1 METHODS

=head2 new

Create a new instance of this class, initializing the
L<WWW::Mechanize> object.

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    my $mech = WWW::Mechanize->new;
    $self->mech($mech);

    return $self;
}

=head2 site_url

Generate a L<URI> for the specified WordPress path.

    my $login_url = $mech->site_url('wp-login.php');

=cut

sub site_url {
    my ($self, @path) = @_;

    # Remove trailing slashes
    my $url = $self->url;
    $url =~ s/\/+$//;

    my $uri = URI->new($url);
    $uri->path_segments($uri->path_segments, @path);

    return $uri;
}

=head2 login

Log in to the WordPress instance using the specified username and
password, storing the resulting cookie.

If there is an error logging in, an exception will be thrown.

=cut

sub login {
    my ($self, $username, $password) = @_;

    my $login_url = $self->site_url(qw/wp-login.php/);

    warn "Logging in via [$login_url]\n" if $self->debug;
    $self->mech->get($login_url);

    my $response = $self->mech->submit_form(
        form_name => 'loginform',
        fields    => {
            log => $username,
            pwd => $password,
        },
    );

    croak "Error submitting login form: " . $response->status_line
        if $response->is_error;

    my $tree = HTML::TreeBuilder->new_from_content($response->content);
    my $error = $tree->look_down('id', 'login_error');
    if ($error) {
        croak "Error logging in: " . $error->as_text;
    }
}

=head2 export_site

Export the WordPress site, storing the resulting file at the specified
location.

=cut

sub export_site {
    my ($self, $filename) = @_;

    my $export_url = $self->site_url(qw/wp-admin export.php/);
    $export_url->query_form(
        mm_start                    => 'all',
        mm_end                      => 'all',
        author                      => 'all',
        'export_taxonomy[category]' => 0,
        export_post_type            => 'all',
        export_post_status          => 'all',
        submit                      => 'Download Export File',
        download                    => 'true',
    );

    warn "Exporting data via [$export_url]\n" if $self->debug;
    my $response = $self->mech->get($export_url);

    if ($response->content_type eq 'text/xml') {
        open my $fh, '>', $filename or croak "Error opening export file: $!";
        print $fh $response->content;
        close $fh;
    }
    else {
        croak 'Did not get an XML response from WordPress when exporting';
    }
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
