use strict;
use warnings;
use lib 't/lib';

use Cpanel::JSON::XS            ();
use Future                      ();
use HTTP::Request::Common       qw( GET POST );
use HTTP::Response              ();
use MetaCPAN::Web::Test         qw( override_api_response );
use MetaCPAN::Web::Test::Replay ();
use Path::Tiny                  qw( path );
use Test::More;

is(
    "$MetaCPAN::Web::Test::Replay::FIXTURE_DIR",
    path('t/fixtures/api')->realpath->stringify,
    'default fixture dir is anchored to the repo'
);

local $MetaCPAN::Web::Test::Replay::FIXTURE_DIR = Path::Tiny->tempdir;

sub key { MetaCPAN::Web::Test::Replay::request_key(shift) }

sub fixture {
    my $file = path( $MetaCPAN::Web::Test::Replay::FIXTURE_DIR,
        key(shift) . '.json' );
    return -e $file
        ? Cpanel::JSON::XS->new->utf8->decode( $file->slurp_raw )
        : undef;
}

sub do_request {
    MetaCPAN::Web::Test::Replay::do_request( undef, request => shift );
}

sub record {
    my ( $req, $res ) = @_;
    local $MetaCPAN::Web::Test::Replay::MODE         = 'record';
    local $MetaCPAN::Web::Test::Replay::orig_request = sub {
        Future->done($res);
    };
    return do_request($req);
}

sub replay {
    local $MetaCPAN::Web::Test::Replay::MODE         = 'replay';
    local $MetaCPAN::Web::Test::Replay::orig_request = sub {
        die 'network used';
    };
    return do_request(shift);
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
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $f = replay( GET '/v1/missing?z=1&access_token=secret' );
    ok( $f->is_failed, 'request failed' );
    like(
        ( $f->failure )[0],
        qr{GET /v1/missing\?access_token=XXX&z=1.*METACPAN_API_MODE=record},
        'failure names request and re-record command'
    );
    is( scalar @warnings, 1, 'miss is warned about' );
    unlike( "@warnings", qr/secret/, 'access_token is redacted' );
};

subtest 'record then replay' => sub {
    for my $body ( "caf\xc3\xa9", "\xff\xfe\x00" ) {
        my $req = GET '/v1/file?n=' . length $body;
        record(
            $req,
            HTTP::Response->new(
                404,
                'Not Found',
                [
                    'Content-Type'   => 'text/plain',
                    'Content-Length' => length $body,
                ],
                $body,
            )
        )->get;

        my $res = replay($req)->get;
        is( $res->code,                   404,   'status replayed' );
        is( $res->content,                $body, 'body bytes replayed' );
        is( $res->header('Content-Type'), 'text/plain', 'type replayed' );
        is( $res->header('Content-Length'),
            undef, 'Content-Length not stored' );
    }

    my $binary = fixture( GET '/v1/file?n=3' );
    ok( exists $binary->{body_base64}, 'non-UTF-8 body stored as base64' );
    ok( !exists $binary->{body},       'and not as text' );
    ok( exists fixture( GET '/v1/file?n=5' )->{body}, 'UTF-8 body as text' );
};

subtest 'POST JSON with non-ASCII body' => sub {
    my $req = POST '/v1/search',
        'Content-Type' => 'application/json',
        Content        =>
        Cpanel::JSON::XS->new->utf8->encode( { q => "caf\x{e9}" } );
    record(
        $req,
        HTTP::Response->new(
            200,                                      'OK',
            [ 'Content-Type' => 'application/json' ], '{"n":1}'
        )
    )->get;

    is( replay($req)->get->content, '{"n":1}', 'response replayed' );
    is( fixture($req)->{request_body},
        qq({"q":"caf\x{e9}"}), 'request body stored as text' );
};

subtest 'record skips 5xx responses' => sub {
    my $req = GET '/v1/flaky';
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $res = record( $req, HTTP::Response->new( 503, 'Unavailable' ) )->get;
    is( $res->code, 503, 'response passed through' );
    ok( !fixture($req), 'no fixture written' );
    like( "@warnings", qr{503 response for GET /v1/flaky}, 'warned' );
};

subtest 'record refuses access_token' => sub {
    for my $req (
        GET('/v1/user?access_token=secret'),
        POST(
            '/v1/user',
            'Content-Type' => 'application/json',
            Content        => '{"access_token":"secret"}'
        ),
        )
    {
        my $f = record( $req, HTTP::Response->new(200) );
        ok( $f->is_failed,  $req->method . ' request refused' );
        ok( !fixture($req), 'no fixture written' );
    }
};

subtest 'override_api_response layers over replay' => sub {
    my $recorded = GET '/v1/recorded';
    record( $recorded, HTTP::Response->new( 200, 'OK', [], 'replayed' ) )
        ->get;

    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = \&Net::Async::HTTP::do_request;
    override_api_response(
        if => sub { $_[1]->uri->path eq '/v1/overridden' },
        sub { [ 200, [], ['overridden'] ] }
    );

    is(
        Net::Async::HTTP::do_request(
            undef, request => GET '/v1/overridden'
        )->get->content,
        'overridden',
        'override wins for matching request'
    );
    is(
        Net::Async::HTTP::do_request( undef, request => $recorded )
            ->get->content,
        'replayed',
        'other requests fall through to replay'
    );
};

done_testing;
