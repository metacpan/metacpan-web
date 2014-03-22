#!/usr/bin/env perl

# Generate the sitemap XML files for the robots.txt file.

use strict;
use warnings;

use FindBin qw ($Bin);
use lib "$Bin/../lib";
use MetaCPAN::Sitemap;

my @parts = (

    # For authors, we're looking for the pauseid, and want to build a URL
    # with 'author' in the path.

    {
        object_type => 'author',
        field_name  => 'pauseid',
        xml_file =>
            '/home/metacpan/metacpan.org/root/static/sitemaps/authors.xml.gz',
        cpan_directory => 'author',
    },

    # For releases, we're looking for a download URL; since we're not
    # building a URL, the cpan_directory is missing, but we also want to
    # filter on only the 'latest' entries.

    {
        object_type => 'release',
        field_name  => 'distribution',
        xml_file =>
            '/home/metacpan/metacpan.org/root/static/sitemaps/releases.xml.gz',
        cpan_directory => 'release',
        filter         => { status => 'latest' },
    }
);

MetaCPAN::Sitemap->new($_)->process for @parts;
