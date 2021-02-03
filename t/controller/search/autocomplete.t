use strict;
use warnings;
use Encode qw( encode is_utf8 );
use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi );
use Cpanel::JSON::XS qw( decode_json );

my @tests = (
    [ moose           => 'Moose',                  1 ],
    [ 'DBIx'          => 'DBIx::Class',            1 ],
    [ "Acme::\x{1dd}" => "Acme::\x{1dd}m\x{254}A", 0 ],
);

test_psgi app, sub {
    my $cb = shift;
    foreach my $tuple (@tests) {

        # turn off the utf8 flag to avoid warnings in test output
        my ( $test, $exp, $get_pod )
            = map { is_utf8($_) ? encode( 'UTF-8' => $_ ) : $_ } @$tuple;

        ok( my $res = $cb->( GET "/search/autocomplete?q=$test" ),
            "GET /search/autocomplete?q=$test" );
        is( $res->code, 200, 'code 200' );
        is(
            $res->header('content-type'),
            'application/json; charset=utf-8',
            'Content-type is application/json'
        );
        ok( my $json = eval { decode_json( $res->content ) }, 'valid json' );
        is( ref $json, 'HASH', 'isa hashref' );
        my $module = $json->{suggestions}->[0];

        if ($exp) {
            ok $module, "Found module for $test";
        }
        else {
            ok !$module, "No results (expected) for $test";
        }

        next unless $module;

        # turn off utf8 flag b/c the below m// doesn't always work with it on
        my $doc = encode( 'UTF-8' => $module->{value} );

        is $doc, $exp, 'got the module we wanted first';

        # if it's not exact, is it a prefix match?
        like $doc, qr/^\Q$exp\E/i, 'first result is a prefix match';

        if ($get_pod) {
            ok( $res = $cb->( GET "/pod/$doc" ), "GET $doc" );
            is( $res->code, 200, 'code 200' );

         # use ok() rather than like() b/c the diag output is huge if it fails
            ok( $res->content =~ /$doc/,
                "/pod/$doc content includes module name '$exp'" );
        }
    }
};

done_testing;
