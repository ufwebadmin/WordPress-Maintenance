use strict;
use warnings;
use File::Spec;
use FindBin;
use WordPress::Maintenance::Config;

use Test::More tests => 75;

my $config = WordPress::Maintenance::Config->new(File::Spec->join($FindBin::Dir, 'site'));
isa_ok($config, 'WordPress::Maintenance::Config');

my $directory = File::Spec->join($FindBin::Dir, 'site');
is($config->directory, $directory);
is($config->subdirectory('www'), File::Spec->join($directory, 'www'));

my $dev = $config->for_environment('dev');
is($dev->{server_group}, 'apache', 'matched dev server_group value');
is($dev->{user}, undef, 'matched dev user value');
is($dev->{group}, 'webadmin', 'matched dev group value');
is($dev->{path}, '/var/www/dev.webadmin.ufl.edu/htdocs/test', 'matched dev path value');
isa_ok($dev->{uri}, 'URI');
is($dev->{uri}, 'http://dev.webadmin.ufl.edu/test', 'matched dev uri value');
is($dev->{uri}->host, 'dev.webadmin.ufl.edu', 'matched dev uri host value');
is($dev->{uri}->path, '/test', 'matched dev uri path value');
is($dev->{base}, '/test/', 'matched dev base value');
is($dev->{shebang}, undef, 'matched dev shebang value');
is($dev->{exclude_robots}, 1, 'matched dev exclude_robots value');
is($dev->{wordpress}->{force_ssl}, 0, 'matched dev force_ssl value');
is($dev->{wordpress}->{multisite}->{enabled}, 0, 'matched dev multisite value');
is($dev->{auth}->{shibboleth}, 0, 'matched dev shibboleth auth value');
is($dev->{auth}->{require}, 0, 'matched dev require auth value');
is($dev->{database}->{host}, 'localhost', 'matched dev database host value');
is($dev->{database}->{port}, undef, 'matched dev database port value');
is($dev->{database}->{user}, 'test', 'matched dev database user value');
is($dev->{database}->{password}, 'secret1', 'matched dev database password value');
is($dev->{database}->{name}, 'test', 'matched dev database name value');
is($dev->{database}->{dump_encoding}, 'utf8', 'matched dev database dump_encoding value');

my $test = $config->for_environment('test');
is($test->{server_group}, undef, 'matched test server_group value');
is($test->{user}, 'wwwuf', 'matched test user value');
is($test->{group}, 'webuf', 'matched test group value');
is($test->{path}, '/nerdc/www/test.test.ufl.edu', 'matched test path value');
isa_ok($test->{uri}, 'URI');
is($test->{uri}, 'http://test.test.ufl.edu', 'matched test uri value');
is($test->{uri}->host, 'test.test.ufl.edu', 'matched test uri host value');
is($test->{uri}->path, '', 'matched test uri path value');
is($test->{base}, '/', 'matched test base value');
is($test->{shebang}, '#!/usr/local/bin/php', 'matched test shebang value');
is($test->{exclude_robots}, 1, 'matched test exclude_robots value');
is($test->{wordpress}->{force_ssl}, 1, 'matched test force_ssl value');
is($test->{wordpress}->{multisite}->{enabled}, 0, 'matched test multisite value');
is($test->{auth}->{shibboleth}, 1, 'matched test shibboleth auth value');
is($test->{auth}->{require}, 1, 'matched test require auth value');
is($test->{database}->{host}, 'mysql01.osg.ufl.edu', 'matched test database host value');
is($test->{database}->{port}, 3306, 'matched test database port value');
is($test->{database}->{user}, 'test', 'matched test database user value');
is($test->{database}->{password}, 'secret2', 'matched test database password value');
is($test->{database}->{name}, 'test', 'matched test database name value');
is($test->{database}->{dump_encoding}, 'latin1', 'matched test database dump_encoding value');

my $prod = $config->for_environment('prod');
is($prod->{server_group}, undef, 'matched prod server_group value');
is($prod->{user}, 'wwwuf', 'matched prod user value');
is($prod->{group}, 'webuf', 'matched prod group value');
is($prod->{path}, '/nerdc/www/test.ufl.edu', 'matched prod path value');
isa_ok($prod->{uri}, 'URI');
is($prod->{uri}, 'http://test.ufl.edu', 'matched prod uri value');
is($prod->{uri}->host, 'test.ufl.edu', 'matched prod uri host value');
is($prod->{uri}->path, '', 'matched prod uri path value');
is($prod->{base}, '/', 'matched prod base value');
is($prod->{shebang}, '#!/usr/local/bin/php', 'matched prod shebang value');
is($prod->{exclude_robots}, 0, 'matched prod exclude_robots value');
is($prod->{wordpress}->{force_ssl}, 1, 'matched prod force_ssl value');
is($prod->{wordpress}->{multisite}->{enabled}, 0, 'matched prod multisite value');
is($prod->{auth}->{shibboleth}, 1, 'matched prod shibboleth auth value');
is($prod->{auth}->{require}, 1, 'matched prod require auth value');
is($prod->{database}->{host}, 'mysql01.osg.ufl.edu', 'matched prod database host value');
is($prod->{database}->{port}, 3306, 'matched prod database port value');
is($prod->{database}->{user}, 'test', 'matched prod database user value');
is($prod->{database}->{password}, 'secret3', 'matched prod database password value');
is($prod->{database}->{name}, 'test', 'matched prod database name value');
is($prod->{database}->{dump_encoding}, 'latin1', 'matched prod database dump_encoding value');

my $users = $config->users;
is_deeply($users, [ qw/akirby dwc gtmcknig mr2 trammell/ ], 'got correct list of users');

my $keys = $config->keys;
is($keys->{auth}, 'ZnZc8J/HsBOe8uPmRT+0iQxTrIRgS+/7VYb2vd87ONEircjP6cBqJ9tAhWZF+tgckfK0IpkKq7QVHhLKFqe9RQ', 'matched auth key');
is($keys->{secure_auth}, 'xY2WZ/wB6rbGkSZ9vBwecrtC4IvSRnZLsCwF2fRZ0/q+k5MBoRG9Br2reugTu/8c6a3RIL5r0uehf8iKgWD0EA', 'matched secure_auth key');
is($keys->{logged_in}, 'QRjXU8aRda+ID08z/el3MxEImKWzJoWEA3LE+7Bcdru7iLUgkMqkTMFVK2z5mKGWiUlViibJfj2qFybqpxvoEA', 'matched logged_in key');
is($keys->{nonce}, 'jug9EB57ZsjIxYz3abf4gikqwBg/BgD+B+keBs9AG4VjfFRYXqGnOzx4XeyPImH7wOkP5tQGiNS26XCsu0TEyA', 'matched nonce key');

my $salts = $config->salts;
is($salts->{auth}, 'rj56iqrEvtQ/T0BOlm2+4BYvPJiSk9vIAEcot+/GcZMU18lv0cOJk0F0gopOda/XLH0qbs2ahGzyfJkNRAuxzg', 'matched auth salt');
is($salts->{secure_auth}, 'zrwpl7FdynLNe0WCCXkXxkG/BnRN61gNRX48A21TucO8HHPhUjZAw8AW7qoXmVgoGRREPE71KKvM5dMolNO0iQ', 'matched secure_auth salt');
is($salts->{logged_in}, 'nBB6jrifc6sVnmkgm1aE4r2hH9auomC3Jt6KhrPIApIv54JcN8xt98qRnqXh1kEICPjX/gWxeCSXguPQ5mfJrQ', 'matched logged_in salt');
is($salts->{nonce}, '5PRfyeDCr4mVjCvzcL8nv/BNZxsKpHFtgkJSnSiQXd2tLoZ45zUswdfUV7NhDhixhAbQcPgzV3evZQHEiZTtgg', 'matched nonce salt');
