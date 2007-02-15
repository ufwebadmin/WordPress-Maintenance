#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Getopt::Long;
use URI;


##
## Globals
##

our $DEFAULT_SHEBANG  = '#!/usr/local/bin/php';


##
## Main script
##

main(@ARGV);
sub main {
    my ($source, $destination, $environment, $checkout, $shebang) = @_;
    die usage() unless GetOptions(
        'source|s=s'           => \$source,
        'destination|dest|d=s' => \$destination,
        'environment|env|e=s'  => \$environment,
        'checkout|C'           => \$checkout,
        'shebang|S'            => \$shebang,
    );
    die "Please provide a site URI, environment, and destination\n"
        unless $source and $destination and $environment;

    # rsync $source to staging directory
    # rsync environment configuration to staging directory
    # add shebang if requested
    # cp staging site to destination
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -s, --site           The path to the site staging area SVN checkout
  -e, --environment    The environment to deploy (dev, test, prod)
  -d, --destination    The destination path or SCP target
  -C, --checkout       Use svn checkout instead of svn export to deploy the site
  -S, --shebang        Add a shebang line to the top of PHP files (where necessary)
END_OF_USAGE
}
