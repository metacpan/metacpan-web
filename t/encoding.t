# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test qw( override_api_response );
use Encode qw( encode is_utf8 );

my ( $res_body, $content_type ) = ( q{}, 'text/plain' );

# hijack all requests
my $api_req;
override_api_response sub {
    $api_req = $_[1];
    return [ 200, [ Content_Type => $content_type ], [$res_body] ];
};

use MetaCPAN::Web::Model::API::Module ();
my $model
    = MetaCPAN::Web::Model::API::Module->new( api => 'http://example.com' );

# $body
# $body, $type
sub get_json {
    $res_body     = shift;
    $content_type = shift if @_;
    return $model->source(qw( who cares ))->get;
}

sub get_raw {
    get_json(@_)->{raw};
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub test_raw_response {
    my ( $raw, $exp, $desc, %opts ) = @_;
    subtest $desc => sub {
        ok !is_utf8($raw), 'raw is octets';

        my $got = get_raw($raw);
        is $got, $exp, 'response decoded as expected';

        {
            my ( $ok, $desc ) = ( is_utf8($got), 'utf8' );
            ( $ok, $desc ) = ( !$ok, 'not utf8' )
                if $opts{not_utf8};
            ok $ok, "response is $desc";
        }

        if ( my $w = $opts{warnings} ) {
            for my $i ( map $_ * 2, 0 .. @$w / 2 - 1 ) {
                my ( $re, $desc ) = @{$w}[ $i, $i + 1 ];
                like pop(@warnings), $re, $desc;
            }
        }
        else {
            ok !@warnings, 'no warnings'
                or diag shift @warnings;
        }
    };
}

subtest 'check json returned from the api' => sub {
    $content_type = 'application/json';

    # make sure the usual json response decodes
    is_deeply get_json('{"fake": "json"}'), { fake => 'json' },
        'decoded json';

    foreach my $test (
        [ qq[{"yo": "arr! \\u2620"}],      '\u' ],
        [ qq[{"yo": "arr! \342\230\240"}], 'bytes' ],
        )
    {
        my ( $string, $desc ) = @$test;
        my $struct = get_json($string);
        ok is_utf8( $struct->{yo} ),
            "JSON decodes $desc into character string";
        is_deeply $struct,
            { yo => "arr! \x{2620}" },
            'decoded piratey json with utf-8';
    }
};

foreach my $ctype ( 'text/plain', 'application/json' ) {
    $content_type = $ctype;

    # if application/json fails to decode as json
    # it should go through the same process as any other content type
    subtest "check raw responses from the api (content-type: $ctype)" => sub {

        my $lax_perl_char = do {
            no warnings qw(portable);
            "\x{FFFF_FFFF}";
        };

        # test that a raw, non-utf8 response is unchanged
        foreach my $bad (
            [
                encode( utf8 => "foo${lax_perl_char}bar" ),
                'encoded lax perl utf8 chars'
            ],
            [
                encode( utf8 => "=encoding  utf8\n\nfoo${lax_perl_char}bar" ),
                '=encoding utf8 with bad chars'
            ],
            [ "\225 cp1252 bullet", 'invalid utf-8 bytes' ],

            # we ignore =encoding in raw responses
            [
                "=pod\n\n=encoding latin9\n\nsome pod \xa4\n\n=cut\n",
                'non-utf8 chars'
            ],
            [
                "=pod\n\n=encoding foo-bar-baz\n\nsome char \xfe",
                'unknown =encoding ignored'
            ],
            )
        {
            test_raw_response(
                $bad->[0], $bad->[0], $bad->[1] . ' come back as is',
                warnings => [ qr/does not map to Unicode/, 'encode croaked' ],
                not_utf8 => 1,
            );
        }

        # BLACK FLORETTE
        foreach my $str (
            encode( 'UTF-8' => "foo\x{273f}bar" ),
            join( q{},
                map {chr} 0x66, 0x6f, 0x6f, 0xe2, 0x9c,
                0xbf,           0x62, 0x61, 0x72 ),
            )
        {
            test_raw_response( $str, "foo\x{273f}bar", 'UTF-8 decodes' );
        }

        # HEAVY BLACK HEART
        test_raw_response(
            "i \342\235\244 metacpan",
            "i \x{2764} metacpan",
            'utf-8 bytes decode to perl string'
        );

        # not sure if we'll ever actually get undef
        is get_raw(undef), q{}, 'undef becomes blank';
        ok !@warnings, 'no warnings for undef' or diag shift @warnings;

        {
            # not sure if we'll ever actually get blessed object
            my $b = Blessed_String->new('holy');
            ok ref $b, 'blessed ref';
            is "$b", 'holy', 'stringifies correctly';
            test_raw_response( $b, 'holy', 'blessed string' );
        }
    };
}

subtest 'check requests sent to the api' => sub {
    check_request(
        'simple GET',
        [ '/oogie/boogie/song', undef, {} ],
        {
            content => q{},
            method  => 'GET',
            uri     => '/oogie/boogie/song',
        },
    );

    check_request(
        'utf8 search',
        [ '/sandy/claws' => { "\x{1f36a}" => 'cookies', } ],
        {
            content => qq<{"\360\237\215\252":"cookies"}>,
            method  => 'POST',
            uri     => '/sandy/claws',
        },
    );

    check_request(
        'PUT json with character string',
        [
            '/whats/this' =>
                { mistletoe => "1F384 \x{1F384} CHRISTMAS TREE" },
            { access_token => 'nightmare' }, 'PUT',
        ],
        {
            content =>
                qq<{"mistletoe":"1F384 \xf0\x9f\x8e\x84 CHRISTMAS TREE"}>,
            method => 'PUT',
            uri    => '/whats/this?access_token=nightmare',
        },
    );
};

done_testing;

{
    package    # no_index
        Blessed_String;
    sub new { bless [ $_[1] ], $_[0]; }
    use overload '""' => sub { shift->[0] };
}

sub check_request {
    my ( $desc, $args, $exp ) = @_;
    my $uri = $model->api->clone;
    $uri->path_query( $exp->{uri} );
    $exp->{uri} = $uri;
    $model->request(@$args);

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # check attributes that were specified
    foreach my $k ( sort keys %$exp ) {
        is $api_req->$k, $exp->{$k}, "$desc (matched $k)";
    }
}
