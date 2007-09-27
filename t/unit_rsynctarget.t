use strict;
use warnings;
use File::Spec;
use FindBin;
use WordPress::Maintenance::Config;
use WordPress::Maintenance::RsyncTarget;

use Test::More tests => 18;

my $config = WordPress::Maintenance::Config->new(File::Spec->join($FindBin::Dir, 'site'));

my $dev = WordPress::Maintenance::RsyncTarget->new($config->for_environment('dev'));
isa_ok($dev, 'WordPress::Maintenance::RsyncTarget');
is($dev, '/var/www/dev.webadmin.ufl.edu/htdocs/test', 'dev target is correct');
ok(! $dev->is_remote, 'dev target is not remote');

my $dev_subdirectory = $dev->subdirectory('wp-content', 'uploads');
isa_ok($dev_subdirectory, 'WordPress::Maintenance::RsyncTarget');
is($dev_subdirectory, '/var/www/dev.webadmin.ufl.edu/htdocs/test/wp-content/uploads', 'dev target with additional path is correct');
ok(! $dev_subdirectory->is_remote, 'dev target with additional path is not remote');

my $test = WordPress::Maintenance::RsyncTarget->new($config->for_environment('test'));
isa_ok($test, 'WordPress::Maintenance::RsyncTarget');
is($test, 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.test.ufl.edu', 'test target is correct');
ok($test->is_remote, 'test target is remote');

my $test_subdirectory = $test->subdirectory('wp-content', 'uploads');
isa_ok($test_subdirectory, 'WordPress::Maintenance::RsyncTarget');
is($test_subdirectory, 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.test.ufl.edu/wp-content/uploads', 'test target with additional path is correct');
ok($test_subdirectory->is_remote, 'test target with additional path is remote');

my $prod = WordPress::Maintenance::RsyncTarget->new($config->for_environment('prod'));
isa_ok($prod, 'WordPress::Maintenance::RsyncTarget');
is($prod, 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.ufl.edu', 'prod target is correct');
ok($prod->is_remote, 'prod target is remote');

my $prod_subdirectory = $prod->subdirectory('wp-content', 'uploads');
isa_ok($prod_subdirectory, 'WordPress::Maintenance::RsyncTarget');
is($prod_subdirectory, 'wwwuf@nersp.osg.ufl.edu:/nerdc/www/test.ufl.edu/wp-content/uploads', 'prod target with additional path is correct');
ok($prod_subdirectory->is_remote, 'prod target with additional path is remote');
