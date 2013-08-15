#!/usr/bin/env perl

#  Generate the sitemap XML files for the robots.txt file.

use strict;
use warnings;

use lib './lib';

use MetaCPAN::Sitemap;

{
    my @parts = (
        {   objectType    => 'author',
            fieldName     => 'pauseid',
            xmlFile       => '/tmp/authors.xml',
            cpanDirectory => 'author',
        },
        {   objectType    => 'distribution',
            fieldName     => 'name',
            xmlFile       => '/tmp/modules.xml',
            cpanDirectory => 'module',
        },
        {   objectType => 'release',
            fieldName  => 'download_url',
            xmlFile    => '/tmp/releases.xml',
        }
    );

    foreach my $part ( @parts ) {

        MetaCPAN::Sitemap::process ( $part );
    }
}
