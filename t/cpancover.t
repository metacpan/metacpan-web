use strict;
use warnings;

use FindBin;
use MetaCPAN::CPANCover;
use Path::Class qw( file );
use Test::Most;
use WWW::Mechanize;

# don't use cache when testing
my $cover = MetaCPAN::CPANCover->new(
    uri => file( '', $FindBin::Bin, 'test-data', 'cpancover.json' ),
    ua  => WWW::Mechanize->new,
);

my $reports = $cover->current_reports;

is_deeply( $reports, { 'ACL-Lite-0.0004' => 1 }, 'reports are available' );

done_testing();
