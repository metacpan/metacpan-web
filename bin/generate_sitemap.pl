#!/usr/bin/env perl

#  Generate the sitemap XML files for the robots.txt file.

use strict;
use warnings;
use Data::Dumper;
use FindBin qw ($Bin);
use lib "$Bin/../lib";

use MetaCPAN::Sitemap;

my @parts = (

    #  For authors, we're looking for the pauseid, and want to build a URL
    #  with 'author' in the path.

    {   object_type    => 'author',
        field_name     => 'pauseid',
        xml_file       => '/tmp/authors.xml.gz',
        cpan_directory => 'author',
    },

    #  For distributions, we're looking for the distribution name, and we
    #  want to build a URL with 'module' in the path.

    {   object_type    => 'distribution',
        field_name     => 'name',
        xml_file       => '/tmp/modules.xml.gz',
        cpan_directory => 'pod',
    },

    #  For releases, we're looking for a download URL; since we're not
    #  building a URL, the cpan_directory is missing, but we also want to
    #  filter on only the 'latest' entries.

    {   object_type    => 'release',
        field_name     => 'distribution',
        xml_file       => '/tmp/releases.xml.gz',
        cpan_directory => 'release',
        filter         => { status => 'latest' },
    }
);

MetaCPAN::Sitemap->new($_)->process for @parts;
