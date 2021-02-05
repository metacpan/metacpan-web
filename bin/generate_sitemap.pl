#!/usr/bin/env perl

# Generate the sitemap XML files for the robots.txt file.

use strict;
use warnings;

use File::Basename ();
use File::Spec     ();
use Cwd            ();
use Config::ZOMG   ();

my $root_dir;

BEGIN {
    my $bin_dir = File::Basename::dirname(__FILE__);
    $root_dir
        = Cwd::abs_path( File::Spec->catdir( $bin_dir, File::Spec->updir ) );
}
use lib "$root_dir/lib";
use MetaCPAN::Sitemap;

my $config = Config::ZOMG->open(
    name => 'MetaCPAN::Web',
    path => $root_dir,
);

my $out_dir = "$root_dir/root/static/sitemaps/";
mkdir $out_dir;

my $web_host = $config->{web_host};
$web_host =~ s{/\z}{};
my $sitemaps = $config->{sitemap};

for my $file ( sort keys %$sitemaps ) {
    my %sm_config = %{ $sitemaps->{$file} };
    my $full_file = $out_dir . $file;
    $sm_config{url_prefix} ||= do {
        my $metacpan_url = $sm_config{metacpan_url};
        s{/\z}{}, s{\A/}{} for $metacpan_url;
        "$web_host/$metacpan_url/";
    };
    $sm_config{api} = $config->{api};
    my $sitemap = MetaCPAN::Sitemap->new(%sm_config);
    $sitemap->write($full_file);
}
