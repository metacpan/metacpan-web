use strict;
use warnings;
use lib 't/lib';

use Cpanel::JSON::XS    qw( decode_json );
use MetaCPAN::Web::Test qw( app GET test_psgi );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/healthcheck' ), 'GET /healthcheck' );
    is( $res->code, 200, 'code 200' );
    is $res->header('Content-Type'), 'application/json',
        'correct Content-Type';
    my $data = decode_json( $res->content );
    is $data->{status}, 'healthy', 'has correct status';
};

done_testing;
