use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

my @tests
    = qw(/activity /activity?author=PERLER /activity?distribution=Moose);

test_psgi app, sub {
    my $cb = shift;
    foreach my $test (@tests) {
        ok( my $res = $cb->( GET $test), $test );
        is( $res->code, 200, 'code 200' );
        is( $res->header('content-type'),
            'image/svg+xml', 'Content-type is image/svg+xml' );
        ok( my $tx = eval { tx($res) }, 'valid xml' );
    }
};

done_testing;
