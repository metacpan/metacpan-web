use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;
use JSON::XS;

my @tests = qw(moose moose">);

test_psgi app, sub {
    my $cb = shift;
    foreach my $test (@tests) {
        ok( my $res = $cb->( GET "/search/autocomplete?q=$test" ),
            "GET /search/autocomplete?q=$test" );
        is( $res->code, 200, 'code 200' );
        is( $res->header('content-type'),
            'application/json', 'Content-type is application/json' );
        ok( my $json = eval { decode_json( $res->content ) }, 'valid json' );
        is(ref $json, 'ARRAY', 'isa arrayref');
        my $module = shift @$json;
        next unless $module;
        ok( $res = $cb->( GET "/module/$module->{documentation}" ),
            "GET $module->{documentation}" );
            is( $res->code, 200, 'code 200' );
        ok($res->content =~ /$module->{documentation}/, 'includes module name');
    }
};

done_testing;
