use strict;
use warnings;
use lib 't/lib';

use Future                      ();
use HTTP::Request::Common       qw( GET POST );
use HTTP::Response              ();
use MetaCPAN::Web::Test::Replay ();
use Path::Tiny                  qw( path );
use Test::More;

local $MetaCPAN::Web::Test::Replay::FIXTURE_DIR = Path::Tiny->tempdir;

sub key { MetaCPAN::Web::Test::Replay::request_key(shift) }

sub do_request {
    MetaCPAN::Web::Test::Replay::do_request( undef, request => shift );
}

subtest 'request key canonicalization' => sub {
    my $json = 'application/json';
    is(
        key(
            POST 'https://a.test/v1/x?b=1&a=2',
            'Content-Type' => $json,
            Content        => '{"q":1,"p":[2,3]}'
        ),
        key(
            POST 'http://localhost/v1/x?a=2&b=1',
            'Content-Type' => $json,
            Content        => '{ "p": [2,3], "q": 1 }'
        ),
        'query and JSON key order, host and scheme are ignored'
    );
    isnt(
        key( GET '/v1/x?a=1&a=2' ),
        key( GET '/v1/x?a=2&a=1' ),
        'repeated query values keep their order'
    );
};

subtest 'replay miss fails' => sub {
    local $MetaCPAN::Web::Test::Replay::MODE = 'replay';
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $f = do_request( GET '/v1/missing?z=1' );
    ok( $f->is_failed, 'request failed' );
    like(
        ( $f->failure )[0],
        qr{GET /v1/missing\?z=1.*METACPAN_API_MODE=record},
        'failure names request and re-record command'
    );
    is( scalar @warnings, 1, 'miss is warned about' );
};

subtest 'record then replay' => sub {
    for my $body ( "caf\xc3\xa9", "\xff\xfe\x00" ) {
        my $req = GET '/v1/file?n=' . length $body;
        {
            local $MetaCPAN::Web::Test::Replay::MODE         = 'record';
            local $MetaCPAN::Web::Test::Replay::orig_request = sub {
                Future->done( HTTP::Response->new(
                    404,
                    'Not Found',
                    [
                        'Content-Type'   => 'text/plain',
                        'Content-Length' => length $body,
                    ],
                    $body,
                ) );
            };
            do_request($req)->get;
        }

        my $res = do {
            local $MetaCPAN::Web::Test::Replay::MODE         = 'replay';
            local $MetaCPAN::Web::Test::Replay::orig_request = sub {
                die 'network used';
            };
            do_request($req)->get;
        };
        is( $res->code,                   404,   'status replayed' );
        is( $res->content,                $body, 'body bytes replayed' );
        is( $res->header('Content-Type'), 'text/plain', 'type replayed' );
        is( $res->header('Content-Length'),
            undef, 'Content-Length not stored' );
    }

    my @stored
        = map { path($_)->slurp_raw }
        path($MetaCPAN::Web::Test::Replay::FIXTURE_DIR)->children;
    is( scalar( grep {/"body_base64"/} @stored ),
        1, 'non-UTF-8 body stored as base64' );
};

done_testing;
