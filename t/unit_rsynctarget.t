use strict;
use warnings;
use File::Spec;
use FindBin;
use WordPress::Maintenance::Config;
use WordPress::Maintenance::RsyncTarget;

use Test::More tests => 12;

my $config = WordPress::Maintenance::Config->new(File::Spec->join($FindBin::Dir, 'site'));

my $dev = WordPress::Maintenance::RsyncTarget->new($config->for_environment('dev'));
isa_ok($dev, 'WordPress::Maintenance::RsyncTarget');
is($dev, '/var/www/dev.webadmin.ufl.edu/htdocs/test', 'dev target is correct');
is(File::Spec->join($dev, 'wp-content', 'uploads'), '/var/www/dev.webadmin.ufl.edu/htdocs/test/wp-content/uploads', 'dev target with additional path is correct');
ok(! $dev->is_remote, 'dev target is not remote');

my $test = WordPress::Maintenance::RsyncTarget->new($config->for_environment('test'));
isa_ok($test, 'WordPress::Maintenance::RsyncTarget');
is($test, 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.test.ufl.edu', 'test target is correct');
is(File::Spec->join($test, 'wp-content', 'uploads'), 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.test.ufl.edu/wp-content/uploads', 'test target with additional path is correct');
ok($test->is_remote, 'test target is remote');

my $prod = WordPress::Maintenance::RsyncTarget->new($config->for_environment('prod'));
isa_ok($prod, 'WordPress::Maintenance::RsyncTarget');
is($prod, 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.ufl.edu', 'prod target is correct');
is(File::Spec->join($prod, 'wp-content', 'uploads'), 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.ufl.edu/wp-content/uploads', 'prod target with additional path is correct');
ok($prod->is_remote, 'test target is remote');
