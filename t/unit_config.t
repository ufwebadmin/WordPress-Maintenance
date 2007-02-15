use strict;
use warnings;
use File::Spec;
use FindBin;
use WordPress::Maintenance::Config;

use Test::More tests => 50;

my $config = WordPress::Maintenance::Config->new(File::Spec->join($FindBin::Dir, 'site'));
isa_ok($config, 'WordPress::Maintenance::Config');

my $dev = $config->for_environment('dev');
is($dev->{server_group}, 'apache');
is($dev->{user}, undef);
is($dev->{group}, 'webadmin');
is($dev->{path}, '/var/www/dev.webadmin.ufl.edu/htdocs/test');
is($dev->{uri}, 'http://dev.webadmin.ufl.edu/test');
is($dev->{base}, '/test/');
is($dev->{shebang}, undef);
is($dev->{exclude_robots}, 1);
is($dev->{wordpress}->{wp_cache}->{enabled}, 0);
is($dev->{wordpress}->{options}->{fake_cache_ttl}, 300);
is($dev->{database}->{host}, 'localhost');
is($dev->{database}->{port}, undef);
is($dev->{database}->{user}, 'test');
is($dev->{database}->{password}, 'secret1');
is($dev->{database}->{name}, 'test');
is($dev->{database}->{dump_encoding}, 'utf8');

my $test = $config->for_environment('test');
is($test->{server_group}, undef);
is($test->{user}, 'wwwuf');
is($test->{group}, 'webuf');
is($test->{path}, '/nerdc/www/test.test.ufl.edu');
is($test->{uri}, 'http://test.test.ufl.edu');
is($test->{base}, '/');
is($test->{shebang}, '#!/usr/local/bin/php');
is($test->{exclude_robots}, 1);
is($test->{wordpress}->{wp_cache}->{enabled}, 1);
is($test->{wordpress}->{options}->{fake_cache_ttl}, 3600);
is($test->{database}->{host}, 'mysql01.osg.ufl.edu');
is($test->{database}->{port}, 3306);
is($test->{database}->{user}, 'test');
is($test->{database}->{password}, 'secret2');
is($test->{database}->{name}, 'test');
is($test->{database}->{dump_encoding}, 'latin1');

my $prod = $config->for_environment('prod');
is($prod->{server_group}, undef);
is($prod->{user}, 'wwwuf');
is($prod->{group}, 'webuf');
is($prod->{path}, '/nerdc/www/test.ufl.edu');
is($prod->{uri}, 'http://test.ufl.edu');
is($prod->{base}, '/');
is($prod->{shebang}, '#!/usr/local/bin/php');
is($prod->{exclude_robots}, 0);
is($prod->{wordpress}->{wp_cache}->{enabled}, 1);
is($prod->{wordpress}->{options}->{fake_cache_ttl}, 3600);
is($prod->{database}->{host}, 'mysql01.osg.ufl.edu');
is($prod->{database}->{port}, 3306);
is($prod->{database}->{user}, 'test');
is($prod->{database}->{password}, 'secret3');
is($prod->{database}->{name}, 'test');
is($prod->{database}->{dump_encoding}, 'latin1');

my $users = $config->users;
is_deeply($users, [ qw/akirby dwc gtmcknig mr2 trammell/ ]);
