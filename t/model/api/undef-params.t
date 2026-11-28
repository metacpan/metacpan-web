use strict;
use warnings;
use lib 't/lib';

use Future                    ();
use HTTP::Response            ();
use MetaCPAN::Web::Model::API ();
use Test::More;

my $model = MetaCPAN::Web::Model::API->new( api => 'http://localhost' );
$model->client;

my $uri;
no warnings 'redefine';
local *Net::Async::HTTP::do_request = sub {
    my ( undef, %args ) = @_;
    $uri = $args{request}->uri;
    return Future->done( HTTP::Response->new(
        200, 'OK', [ 'Content-Type' => 'application/json' ], '{}',
    ) );
};

# Several undef keys so hash order can't make this pass by luck.
$model->request( '/x', undef,
    { a => 1, b => undef, c => undef, d => undef, e => undef } )->get;

is( $uri->query, 'a=1', 'undef params are omitted from the query' );

done_testing;
