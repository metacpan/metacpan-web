use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi );

test_psgi app, sub {
    my $cb = shift;

    {
        ok( my $res = $cb->( GET '/module/DOESNTEXIST/permissions' ),
            'GET /module/DOESNTEXIST/permissions' );
        is( $res->code, 404, 'not found' );
    }
    {
        ok( my $res = $cb->( GET '/module/Moose/permissions' ),
            'GET /module/Moose/permissions' );
        is( $res->code, 200, 'found' );
        like( $res->content, qr{ETHER}, 'ETHER in content' );
    }
    {
        ok( my $res = $cb->( GET '/dist/DOESNTEXIST/permissions' ),
            'GET /dist/DOESNTEXIST/permissions' );
        is( $res->code, 404, 'not found' );
    }
    {
        ok( my $res = $cb->( GET '/dist/Moose/permissions' ),
            'GET /dist/Moose/permission' );
        is( $res->code, 200, 'found' );
        like( $res->content, qr{ETHER}, 'ETHER in content' );
    }

    {
        ok( my $res = $cb->( GET '/author/!!!DOESNTEXIST/permissions' ),
            'GET /author/DOESNTEXIST/permissions' );
        is( $res->code, 404, 'not found' );
    }
    {
        ok( my $res = $cb->( GET '/author/OALDERS/permissions' ),
            'GET /author/OALDERS/permissions' );
        is( $res->code, 200, 'found' );
        like( $res->content, qr{OALDERS},        'OALDERS in content' );
        like( $res->content, qr{HTML::Restrict}, 'owner in content' );
        like( $res->content, qr{LWP::UserAgent}, 'co-maint in content' );
    }
};

done_testing;
