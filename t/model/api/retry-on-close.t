use strict;
use warnings;
use lib 't/lib';

use Future                    ();
use HTTP::Response            ();
use MetaCPAN::Web::Model::API ();
use Test::More;

my $model = MetaCPAN::Web::Model::API->new( api => 'http://localhost' );

# Ensure client is initialized before we patch do_request.
$model->client;

subtest 'retries once on connection closed' => sub {
    my $attempt = 0;
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        $attempt++;
        if ( $attempt == 1 ) {
            return Future->fail( 'Connection closed while awaiting header',
                'http', );
        }
        return Future->wrap( HTTP::Response->new(
            200,                                      'OK',
            [ 'Content-Type' => 'application/json' ], '{"ok":1}',
        ) );
    };

    my $result = $model->request('/test')->get;
    is( $attempt,      2,      'made exactly 2 attempts' );
    is( ref $result,   'HASH', 'got decoded JSON response' );
    is( $result->{ok}, 1,      'response body is correct' );
};

subtest 'does not retry non-connection errors' => sub {
    my $attempt = 0;
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        $attempt++;
        return Future->fail( 'Timed out', 'http' );
    };

    my $f = $model->request('/test');
    $f->await;
    is( $attempt, 1, 'only 1 attempt' );
    ok( $f->is_failed, 'request failed' );
    like( ( $f->failure )[0], qr/Timed out/, 'error propagated as-is' );
};

subtest 'preserves failure metadata' => sub {
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        return Future->fail( 'Something broke', 'http', undef, 'extra' );
    };

    my $f = $model->request('/test');
    $f->await;
    my @failure = $f->failure;
    is( $failure[0], 'Something broke', 'message preserved' );
    is( $failure[1], 'http',            'category preserved' );
    is( $failure[3], 'extra',           'extra args preserved' );
};

subtest 'gives up after one retry' => sub {
    my $attempt = 0;
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        $attempt++;
        return Future->fail( 'Connection closed while awaiting header',
            'http' );
    };

    my $f = $model->request('/test');
    $f->await;
    is( $attempt, 2, 'only 2 attempts' );
    ok( $f->is_failed, 'request failed' );
    like(
        ( $f->failure )[0],
        qr/Connection closed/,
        'error propagated after retry exhausted'
    );
};

subtest 'does not retry when failure is a reference' => sub {
    my $attempt = 0;
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        $attempt++;
        return Future->fail(
            bless( { msg => 'Connection closed' }, 'SomeException' ),
            'http' );
    };

    my $f = $model->request('/test');
    $f->await;
    is( $attempt, 1, 'only 1 attempt' );
    ok( $f->is_failed, 'request failed' );
};

done_testing;
