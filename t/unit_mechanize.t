#!perl

use strict;
use warnings;
use File::Spec;
use WordPress::Maintenance::Mechanize;

use Test::More tests => 5*3;

# Site URL with trailing slash
{
    my $mech = WordPress::Maintenance::Mechanize->new({
        url => 'http://example.com/~dwc/wordpress/',
        debug => 1,
    });

    _test_mechanize_object(
        $mech,
        'http://example.com/~dwc/wordpress/',
        'http://example.com/~dwc/wordpress/',
    );
}

# Site URL with multiple trailing slashes
{
    my $mech = WordPress::Maintenance::Mechanize->new({
        url => 'http://example.com/~dwc/wordpress/////',
        debug => 1,
    });

    _test_mechanize_object(
        $mech,
        'http://example.com/~dwc/wordpress/////',
        'http://example.com/~dwc/wordpress/',
    );
}

# Site URL with no trailing slash
{
    my $mech = WordPress::Maintenance::Mechanize->new({
        url => 'http://example.com/~dwc/wordpress',
        debug => 1,
    });

    _test_mechanize_object(
        $mech,
        'http://example.com/~dwc/wordpress',
        'http://example.com/~dwc/wordpress/',
    );
}


sub _test_mechanize_object {
    my ($mech, $url, $base_url) = @_;

    isa_ok($mech, 'WordPress::Maintenance::Mechanize');
    is($mech->url, $url, 'URL is correct');
    is($mech->debug, 1, 'Debug flag was set');

    is($mech->site_url(qw/wp-login.php/), $base_url . 'wp-login.php', 'wp-login.php URL is correct');
    is($mech->site_url(qw/wp-admin export.php/), $base_url . 'wp-admin/export.php', 'export.php URL is correct');
}
