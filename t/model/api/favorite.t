use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app override_api_response );
use Test::More;

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

done_testing;
