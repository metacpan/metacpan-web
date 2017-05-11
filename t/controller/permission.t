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

    {
        ok( my $res = $cb->( GET '/permission/author/!!!DOESNTEXIST' ),
            'GET /permission/author/DOESNTEXIST' );
        is( $res->code, 404, 'not found' );
    }
    {
        ok( my $res = $cb->( GET '/permission/author/OALDERS' ),
            'GET /permission/author/OALDERS' );
        is( $res->code, 200, 'found' );
        like( $res->content, qr{OALDERS},        'OALDERS in content' );
        like( $res->content, qr{HTML::Restrict}, 'owner in content' );
        like( $res->content, qr{LWP::UserAgent}, 'co-maint in content' );
    }
};

done_testing;
