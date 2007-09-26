use inc::Module::Install;

perl_version '5.8.1';

name 'WordPress-Maintenance';
all_from 'lib/WordPress/Maintenance.pm';

requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'File::Find';
requires 'File::ShareDir';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'Hash::Merge';
requires 'IO::Select';
requires 'IPC::Open3';
requires 'Net::SSH';
requires 'POSIX';
requires 'Template';
requires 'URI';
requires 'YAML';

build_requires 'File::Spec';
build_requires 'FindBin';
build_requires 'Test::More';

install_script glob('script/*.pl');
install_share 'share';

WriteAll;
