use strict;
use warnings;
use utf8;
use Encode qw(encode is_utf8);
use Test::More;
use MetaCPAN::Web::Test;
use JSON::XS;

my @tests = (
    [moose     => 'Moose'],
    ['moose">'], # no match
    ["Acme::ǝ" => "Acme::ǝmɔA"],
);

test_psgi app, sub {
    my $cb = shift;
    foreach my $pair (@tests) {
        # turn off the utf8 flag to avoid warnings in test output
        my ($test, $exp) = map { is_utf8($_) ? encode("UTF-8" => $_) : $_ } @$pair;

        ok( my $res = $cb->( GET "/search/autocomplete?q=$test" ),
            "GET /search/autocomplete?q=$test" );
        is( $res->code, 200, 'code 200' );
        is( $res->header('content-type'),
            'application/json', 'Content-type is application/json' );
        ok( my $json = eval { decode_json( $res->content ) }, 'valid json' );
        is(ref $json, 'ARRAY', 'isa arrayref');
        my $module = shift @$json;

        if( $exp ){
            ok $module, "Found module for $test";
        }
        else {
            ok !$module, "No results (expected) for $test";
        }

        next unless $module;

        # turn off utf8 flag b/c the below m// doesn't always work with it on
        my $doc = encode("UTF-8" => $module->{documentation});

        is $doc, $exp, 'got the module we wanted first';
        # if it's not exact, is it a prefix match?
        like $doc, qr/^\Q$test\E/i, 'first result is a prefix match';

        ok( $res = $cb->( GET "/pod/$doc" ), "GET $doc" );
            is( $res->code, 200, 'code 200' );

        TODO: {
            local $TODO = 'unicode path names have issues (cpan-api#248)'
                if $exp =~ /[^[:ascii:]]/;

            # use ok() rather than like() b/c the diag output is huge if it fails
            ok($res->content =~ /$doc/, "/pod/$doc content includes module name '$exp'");
        }
    }
};

done_testing;
