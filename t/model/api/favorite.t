use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app override_api_response );
use Test::More;
use Test::Warnings qw( :no_end_test warnings );

my @captured_requests;

override_api_response( sub {
    my ( undef, $req ) = @_;
    push @captured_requests, $req;
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        ['{"favorites":[],"total":0,"took":0}'],
    ];
} );

app();

my $model = MetaCPAN::Web->model('API::Favorite');

subtest 'by_user with undef user returns empty' => sub {
    my $result = $model->by_user(undef)->get;
    is_deeply(
        $result,
        { favorites => [], total => 0, took => 0 },
        'undef user returns empty result'
    );
};

subtest 'by_user defaults page and size' => sub {
    @captured_requests = ();
    $model->by_user('some_user')->get;
    is( scalar @captured_requests, 1, 'one request made' );

    my $uri = $captured_requests[0]->uri;
    like( $uri->path, qr{/favorite/by_user/some_user}, 'correct path' );
    is( $uri->query_param('page'),      1,   'page defaults to 1' );
    is( $uri->query_param('page_size'), 250, 'size defaults to 250' );
};

subtest 'by_user passes page and size' => sub {
    @captured_requests = ();
    $model->by_user( 'some_user', 3, 50 )->get;
    is( scalar @captured_requests, 1, 'one request made' );

    my $uri = $captured_requests[0]->uri;
    is( $uri->query_param('page'),      3,  'page passed through' );
    is( $uri->query_param('page_size'), 50, 'size passed through' );
};

subtest 'by_user rejects invalid page and size' => sub {
    for my $case (
        [ -1,  'abc', 'negative page, non-numeric size' ],
        [ 1.5, 0,     'float page, zero size' ],
        )
    {
        my ( $page, $size, $label ) = @$case;
        @captured_requests = ();
        $model->by_user( 'some_user', $page, $size )->get;

        my $uri = $captured_requests[0]->uri;
        is( $uri->query_param('page'), 1, "$label: page defaults to 1" );
        is( $uri->query_param('page_size'),
            250, "$label: size defaults to 250" );
    }
};

subtest 'recent skips author lookup when favorites lack user' => sub {
    @captured_requests = ();
    override_api_response( sub {
        my ( undef, $req ) = @_;
        push @captured_requests, $req;
        return [
            200,
            [ 'Content-Type' => 'application/json' ],
            ['{"favorites":[{"user":null},{}],"total":2,"took":0}'],
        ];
    } );
    my $data = $model->recent( 1, 10 )->get;
    is_deeply( [ map { $_->uri->path } @captured_requests ],
        ['/v1/favorite/recent'], 'no /author/by_user request' );
    is( scalar @{ $data->{favorites} }, 2, 'favorites passed through' );
};

subtest 'recent maps authors when some favorites lack user' => sub {
    @captured_requests = ();
    override_api_response( sub {
        my ( undef, $req ) = @_;
        push @captured_requests, $req;
        my $body
            = $req->uri->path eq '/v1/author/by_user'
            ? '{"authors":[{"user":"u1","pauseid":"FOO"}]}'
            : '{"favorites":[{"user":"u1"},{}],"total":2,"took":0}';
        return [ 200, [ 'Content-Type' => 'application/json' ], [$body] ];
    } );

    my $data;
    is_deeply( [ warnings { $data = $model->recent( 1, 10 )->get } ],
        [], 'no warnings' );
    is( $captured_requests[1]->uri->query,
        'user=u1', 'by_user queried for defined user only' );
    is( $data->{favorites}[0]{clicked_by_author},
        'FOO', 'u1 favorite gets its author' );
    ok( !exists $data->{favorites}[1]{clicked_by_author},
        'userless favorite is untouched' );
};

done_testing;
