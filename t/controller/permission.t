use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;

    {
        ok( my $res = $cb->( GET '/permission/module/DOESNTEXIST' ),
            'GET /permission/module/DOESNTEXIST' );
        is( $res->code, 404, 'not found' );
    }
    {
        ok( my $res = $cb->( GET '/permission/module/Moose' ),
            'GET /permission/module/Moose' );
        is( $res->code, 200, 'found' );
        like( $res->content, qr{ETHER}, 'ETHER in content' );
    }
    {
        ok( my $res = $cb->( GET '/permission/distribution/DOESNTEXIST' ),
            'GET /permission/distribution/DOESNTEXIST' );
        is( $res->code, 404, 'not found' );
    }
    {
        ok( my $res = $cb->( GET '/permission/distribution/Moose' ),
            'GET /permission/distribution/Moose' );
        is( $res->code, 200, 'found' );
        like( $res->content, qr{ETHER}, 'ETHER in content' );
    }
};

done_testing;
