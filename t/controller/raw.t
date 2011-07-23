use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/module/Moose" ), 'GET /module/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    ok( my $source = $tx->find_value('//a[text()="Source"]/@href'),
        'contains link to Source' );
    $source =~ s/^\/source/\/raw/;
    ok( $res = $cb->( GET $source ), "GET $source" );
    ok( $res->code(200), 'code 200' );
    is( $res->header('Content-Type'),
        'text/html; charset=utf-8',
        'Content-type text/html; charset=utf-8'
    );

    ok( $res = $cb->( GET "$source?download=1" ), "GET $source?download=1" );
    is( $res->header('Content-Disposition'),
        'attachment; filename=Moose.pm',
        'content-disposition attachment with filename set'
    );
    is( $res->header('Content-Type'), 'text/plain; charset=UTF-8',
        'cotent-type text/plain' );

};

done_testing;
