use strict;
use warnings;
use lib 't/lib';

use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi );

test_psgi app, sub {
    my $cb = shift;
    {
        ok( my $res = $cb->( GET '/favicon.ico' ), 'GET /favicon.ico' );
        is( $res->code, 200, 'code 200' );
        unlike $res->header('Cache-Control'), qr/immutable/, "not immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=image
            content_type=image/vnd.microsoft.icon
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/static/opensearch.xml' ),
            'GET /static/opensearch.xml' );
        is( $res->code, 200, 'code 200' );
        unlike $res->header('Cache-Control'), qr/immutable/, "not immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=application
            content_type=application/xml
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/static/fastly_do_not_delete.gif' ),
            'GET /static/fastly_do_not_delete.gif' );
        is( $res->code, 200, 'code 200' );
        unlike $res->header('Cache-Control'), qr/immutable/, "not immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=image
            content_type=image/gif
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/static/icons/grid.svg' ),
            'GET /static/icons/grid.svg' );
        is( $res->code, 200, 'code 200' );
        like $res->header('Cache-Control'), qr/immutable/, "immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=image
            content_type=image/svg+xml
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/static/images/dots.svg' ),
            'GET /static/images/dots.svg' );
        is( $res->code, 200, 'code 200' );
        like $res->header('Cache-Control'), qr/immutable/, "immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=image
            content_type=image/svg+xml
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/static/js/main.mjs' ),
            'GET /static/js/main.mjs' );
        is( $res->code, 200, 'code 200' );
        unlike $res->header('Cache-Control'), qr/immutable/, "not immutable";
        is_deeply [ sort split /,? /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=application
            content_type=application/javascript
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/assets/assets.json' ),
            'GET /assets/assets.json' );
        is( $res->code, 200, 'code 200' );
        like $res->header('Cache-Control'), qr/immutable/, "immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            assets
            content_type=application
            content_type=application/json
        ) ],
            'correct Surrogate-Key';
    }
    {
        ok( my $res = $cb->( GET '/assets/this-file-does-not-exist.js' ),
            'GET /assets/this-file-does-not-exist.js' );
        is( $res->code, 404, 'code 404' );
        unlike $res->header('Cache-Control'), qr/immutable/, "not immutable";
        is_deeply [ sort split /, /, $res->header('Surrogate-Key') ], [ qw(
            content_type=text
            content_type=text/plain
        ) ],
            'correct Surrogate-Key';
    }
};

done_testing;
