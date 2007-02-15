use inc::Module::Install;

name 'WordPress';
all_from 'lib/WordPress.pm';

install_script glob('script/*.pl');
install_share 'share';

WriteAll;
