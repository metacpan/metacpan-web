use strict;
use warnings;
use lib 't/lib';

use Cpanel::JSON::XS    qw( decode_json );
use MetaCPAN::Web::Test qw( app GET override_api_response test_psgi tx );
use Plack::Session      ();
use Test::More;

my $JSON = Cpanel::JSON::XS->new->utf8;

my @captured_requests;

my $user_res;

our $favorites_res = {
    favorites => [ {
        distribution => 'Moose',
        author       => 'ETHER',
        date         => '2025-01-01T00:00:00',
    } ],
    total => 1,
    took  => 5,
};

override_api_response( sub {
    my ( undef, $req ) = @_;

    push @captured_requests, $req;

    if ( $req->url->path eq '/user' ) {
        return [
            200,
            [ 'Content-Type' => 'application/json' ],
            [ $JSON->encode( $user_res // {} ) ],
        ];
    }

    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ $JSON->encode($favorites_res) ],
    ];
} );

no warnings 'once', 'redefine';
my $token;
local *Plack::Session::get = sub {
    return $token
        if $_[1] eq 'token';
    return undef;
};

my $list_url = '/account/favorite/list';
my $json_url = '/account/favorite/list_as_json';

sub by_user_req {
    return grep { $_->uri->path =~ m{/favorite/by_user/} } @captured_requests;
}

test_psgi app, sub {
    my $cb = shift;

    subtest 'list without auth returns 403' => sub {
        $token = undef;
        ok( my $res = $cb->( GET $list_url ), "GET $list_url" );
        is( $res->code, 403, 'returns 403' );
    };

    $token    = 'foobar';
    $user_res = { id => '42' };

    subtest 'list returns 200 with favorites' => sub {
        ok( my $res = $cb->( GET $list_url ), "GET $list_url" );
        is( $res->code, 200, 'returns 200' );
        my $tx = tx($res);
        $tx->ok(
            '//table[@id="metacpan_author_favorites"]',
            'response contains favorites table'
        );
        $tx->like( '//table[@id="metacpan_author_favorites"]',
            qr/Moose/, 'table contains favorite distribution' );
    };

    subtest 'list uses default pagination' => sub {
        @captured_requests = ();
        $cb->( GET $list_url );
        my ($req) = by_user_req();
        ok( $req, 'made a by_user API request' );
        is( $req->uri->query_param('page'), 1, 'page defaults to 1' );
        is( $req->uri->query_param('page_size'),
            100, 'page_size defaults to 100' );
    };

    subtest 'list passes pagination params' => sub {
        my $url = "$list_url?p=2&size=10";
        @captured_requests = ();
        ok( my $res = $cb->( GET $url ), "GET $url" );
        is( $res->code, 200, 'returns 200' );

        my ($req) = by_user_req();
        ok( $req, 'made a by_user API request' );
        is( $req->uri->query_param('page'),      2,  'page passed through' );
        is( $req->uri->query_param('page_size'), 10, 'size passed through' );
    };

    subtest 'list caps oversized page_size' => sub {
        @captured_requests = ();
        $cb->( GET "$list_url?size=200" );
        my ($req) = by_user_req();
        ok( $req, 'made a by_user API request' );
        is( $req->uri->query_param('page_size'),
            100, 'size >100 falls back to default' );
    };

    subtest 'list_as_json without auth returns 403' => sub {
        $token = undef;
        ok( my $res = $cb->( GET $json_url ), "GET $json_url" );
        is( $res->code, 403, 'returns 403' );
    };

    $token = 'foobar';

    subtest 'list_as_json returns JSON with faves' => sub {
        ok( my $res = $cb->( GET $json_url ), "GET $json_url" );
        is( $res->code, 200, 'returns 200' );
        like( $res->header('Content-Type'), qr/json/,
            'Content-Type is JSON' );

        my $data = decode_json( $res->content );
        ok( exists $data->{faves}, 'response has faves key' );
        is( ref $data->{faves},         'ARRAY', 'faves is an array' );
        is( scalar @{ $data->{faves} }, 1,       'one favorite returned' );
        is( $data->{faves}[0]{distribution}, 'Moose',
            'correct distribution' );
    };

    subtest 'list_as_json requests all favorites' => sub {
        @captured_requests = ();
        $cb->( GET $json_url );

        my ($req) = by_user_req();
        ok( $req, 'made a by_user API request' );
        is( $req->uri->query_param('page'), 1, 'page is 1' );
        is( $req->uri->query_param('page_size'),
            2000, 'requests up to 2000 favorites' );
    };

    subtest 'list_as_json sets cache headers' => sub {
        ok( my $res = $cb->( GET $json_url ), "GET $json_url" );
        like( $res->header('Cache-Control') // '',
            qr/private/, 'Cache-Control is private' );
    };

    subtest 'list with empty favorites' => sub {
        local $favorites_res = { favorites => [], total => 0, took => 0 };
        ok( my $res = $cb->( GET $list_url ), "GET $list_url" );
        is( $res->code, 200, 'returns 200' );
    };

    subtest 'list_as_json with empty favorites' => sub {
        local $favorites_res = { favorites => [], total => 0, took => 0 };
        ok( my $res = $cb->( GET $json_url ), "GET $json_url" );
        is( $res->code, 200, 'returns 200' );

        my $data = decode_json( $res->content );
        is( scalar @{ $data->{faves} }, 0, 'no favorites returned' );
    };
};

done_testing;
