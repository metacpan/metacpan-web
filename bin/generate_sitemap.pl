#!/usr/bin/env perl

#  Generate the sitemap XML files for the robots.txt file.

use strict;
use warnings;

use FindBin qw ($Bin);
use lib "$Bin/../lib";

use MetaCPAN::Sitemap;

{
    my @parts = (

	#  For authors, we're looking for the pauseid, and want to build a URL
	#  with 'author' in the path.

        {   objectType    => 'author',
            fieldName     => 'pauseid',
            xmlFile       => '/tmp/authors.xml',
            cpanDirectory => 'author',
        },

	#  For distributions, we're looking for the distribution name, and we
	#  want to build a URL with 'module' in the path.

        {   objectType    => 'distribution',
            fieldName     => 'name',
            xmlFile       => '/tmp/modules.xml',
            cpanDirectory => 'module',
        },

	#  For releases, we're looking for a download URL; since we're not
	#  building a URL, the cpanDirectory is missing, but we also want to
	#  filter on only the 'latest' entries.

        {   objectType => 'release',
            fieldName  => 'download_url',
            xmlFile    => '/tmp/releases.xml',
	    filter     => { status => 'latest' },
        }
    );

    foreach my $part ( @parts ) {

        MetaCPAN::Sitemap::process ( $part );
    }
}
