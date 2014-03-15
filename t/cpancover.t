use strict;
use warnings;

use FindBin;
use MetaCPAN::CPANCover;
use Path::Class qw( file );
use Test::Most;
use WWW::Mechanize;

{
    # don't use cache
    my $cover = MetaCPAN::CPANCover->new(
        uri => file( '', $FindBin::Bin, 'test-data', 'cpancover.json' ),
        ua => WWW::Mechanize->new,
    );

    test_contents( $cover, 'without cache' );
}

{
    # assert that cache isn't exploding
    my $cover = MetaCPAN::CPANCover->new(
        uri => file( '', $FindBin::Bin, 'test-data', 'cpancover.json' ), );

    test_contents( $cover, 'with cache' );
}

sub test_contents {
    my $cover       = shift;
    my $description = shift;

    is_deeply(
        $cover->current_reports,
        { 'ACL-Lite-0.0004' => 1 },
        'reports are available ' . $description
    );
    ok(
        $cover->get_report('ACL-Lite-0.0004'),
        'report exists ' . $description
    );
}

done_testing();
