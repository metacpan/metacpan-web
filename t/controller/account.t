use strict;
use warnings;
use MetaCPAN::Web::Test qw( app GET override_api_response POST test_psgi tx );
use Test::More;
use Test::Deep qw( cmp_deeply );
use Cpanel::JSON::XS qw( decode_json encode_json );
use HTTP::Date qw(time2str);
use HTTP::Cookies  ();
use Plack::Session ();

my $api_res;
my $api_req;

my $profile_req;

my $login_req;
my $login_res;

my $user_req;
my $user_res;

my $JSON = Cpanel::JSON::XS->new->allow_nonref->utf8;

override_api_response( sub {
    my ( undef, $req ) = @_;

    my $res;

    if ( $req->method eq 'PUT' ) {
        $profile_req = decode_json( $req->content );
        $res         = $profile_req;
    }
    elsif ( $req->uri->path eq '/oauth2/access_token' ) {
        $login_req = $req;
        $res       = $login_res;
    }
    elsif ( $req->url->path eq '/user' ) {
        $user_req = $req;
        $res      = $user_res;
    }
    else {
        $res = $api_res;
    }

    return [
        200,
        [ "Content-Type" => "application/json" ],
        [ $JSON->encode( $res // {} ) ]
    ];
} );

no warnings 'once', 'redefine';
my $token;
local *Plack::Session::get = sub {
    return $token
        if $_[1] eq 'token';
    return undef;
};

test_psgi app, sub {
    my $cb = shift;

    subtest 'auto' => sub {
        ok(
            my $res = $cb->( GET '/account/profile' ),
            'GET /account/profile without token'
        );
        is( $res->code, 403, '... and the user cannot get in' );
        is( $res->header('Cache-Control'),
            'private',
            '... and the private Cache-Control header for proxies is there' );
        is( $user_req, undef, '... and we did not try to authenticate' );

        $token = 'foobar';

        ok( $res = $cb->( GET '/account/profile' ),
            'GET /account/profile with token but user does not exist' );
        is( $res->code, 403, '... and the user cannot get in' );

        is( $user_req->uri->query_param('access_token'),
            'foobar',
            '... and we tried authenticating with the right token' );
    };

    # (we're always authenticated from now on)
    $user_res = {
        looks_human => \1,
        id          => '5',
    };

    subtest 'GET profile' => sub {
        $api_res = { error => "broken" };

        ok(
            my $res = $cb->( GET '/account/profile' ),
            'GET /account/profile author-error'
        );
        is( $res->code, 200, '... and the user gets in' );
        my $tx = tx($res);
        $tx->like(
            '//div[@class="content account-settings"]',
            qr/connect your account to PAUSE/,
            '... and needs to connect to PAUSE'
        );

        $api_res = {
            asciiname => 'foo',
            email     => ['foobar@cpan.org'],
            name      => 'foo',
            pauseid   => 'FOO',
            updated   => '2017-02-15T22:18:19',
            user      => '12345678901234567890',
            website   => [],
        };

        ok(
            $res = $cb->( GET '/account/profile' ),
            'GET /account/profile happy case'
        );
        is( $res->code, 200, '... and the user gets in' );
        $tx = tx($res);
        $tx->is( '//input[@name="name"]/@value',
            'foo', '... and the form is prefilled' );
    };

    subtest 'POST profile' => sub {

        # still the same $res_body as above

        my $form = [
            'blog.url'      => 'http://example.org/blog1',
            'blog.feed'     => 'http://example.org/feed1',
            'donation.name' => 'donation.name1',
            'donation.id'   => 'donation.id1',
            'profile.name'  => 'github',
            'profile.id'    => 'github_username',
            'profile.name'  => 'stackoverflow',
            'profile.id'    => 'stackoverflow_username',
            'latitude'      => '52.3759 N',
            'longitude'     => '9.7320 E',
            'name'          => "\x{532}\x{561}\x{580}\x{565}\x{582}",
            'asciiname'     => 'asciiname1',
            'city'          => 'city1',
            'region'        => 'region1',
            'country'       => 'country1',
            'extra'         => '{}',
            'donations'     => 'on',
            'website'       => 'http://example.org/web1',
            'website'       => 'http://example.org/web2',
            'email'         => 'foo@example.org',
            'email'         => 'bar@example.org',
            'utf8'          => "\x{1f42a}",
        ];
        subtest 'profile validation' => sub {
            my @bad_form = @$form;
            $bad_form[23] = "\x80";    # asciiname
            ok(
                my $res = $cb->( POST '/account/profile', \@bad_form ),
                'POST /account/profile with non-ASCII asciiname'
            );
            my $tx = tx($res);
            $tx->is( '//legend[@style="color: #600"]',
                "Errors", 'shows errors', );
        };

        ok(
            my $res = $cb->( POST '/account/profile', $form ),
            'POST /account/profile with all fields'
        );

        cmp_deeply(
            $profile_req,
            {
                'email' => [ 'foo@example.org', 'bar@example.org' ],
                'blog'  => [ {
                    'feed' => 'http://example.org/feed1',
                    'url'  => 'http://example.org/blog1',
                } ],
                'asciiname' => 'asciiname1',
                'donation'  => [ {
                    'name' => 'donation.name1',
                    'id'   => 'donation.id1',
                } ],
                'website' =>
                    [ 'http://example.org/web1', 'http://example.org/web2' ],
                'user'    => '12345678901234567890',
                'profile' => [
                    {
                        'id'   => 'github_username',
                        'name' => 'github',
                    },
                    {
                        'id'   => 'stackoverflow_username',
                        'name' => 'stackoverflow',
                    }
                ],
                'location' => [ '52.3759 N', '9.7320 E' ],
                'region'   => 'region1',
                'city'     => 'city1',
                'country'  => 'country1',
                'extra'    => {},
                'updated'  => '2017-02-15T22:18:19',  # set above in $res_body
                'name'     => "\x{532}\x{561}\x{580}\x{565}\x{582}",
                'pauseid'  => 'FOO',
            },
            '... and the API PUT request contains the right stuff'
        );
        my $tx = tx($res);

        $tx->is(
            '//input[@name="name"]/@value',
            "\x{532}\x{561}\x{580}\x{565}\x{582}",
            '... and the new user data is in the page'
        );

        $form = [
            'name'      => "\x{532}\x{561}\x{580}\x{565}\x{582}",
            'asciiname' => 'asciiname1',
            'utf8'      => "\x{1f42a}",
            'city'      => '',
            'region'    => '',
            'country'   => '',
            'extra'     => '',
        ];
        ok(
            $res = $cb->( POST '/account/profile', $form ),
            'POST /account/profile with no fields'
        );
        cmp_deeply(
            $profile_req,
            {
                'updated'   => '2017-02-15T22:18:19',
                'user'      => '12345678901234567890',
                'name'      => "\x{532}\x{561}\x{580}\x{565}\x{582}",
                'asciiname' => 'asciiname1',
                'pauseid'   => 'FOO',
                'country'   => undef,
                'blog'      => undef,
                'city'      => undef,
                'donation'  => undef,
                'email'     => [],
                'location'  => undef,
                'profile'   => undef,
                'website'   => [],
                'region'    => undef,
                'extra'     => undef,
            },
            '... and the API PUT request contains the right stuff'
        );
    };

    subtest 'logout' => sub {
        ok( my $res = $cb->( GET '/account/logout' ), 'GET /account/logout' );
        is( $res->code, 403, '... and the response is 403' );

        ok( $res = $cb->( POST '/account/logout' ), 'POST /account/logout' );
        is( $res->code, 302, '... and the response is a redirect' );
        is( $res->header('location'),
            '/', '... and we get redirected to the index' );

        # prepare a cookie jar with a fake metacpan_secure entry
        my $jar      = HTTP::Cookies->new;
        my $fake_res = HTTP::Response->new(
            200, '',
            [
                'Set-Cookie' => 'metacpan_secure=12345; path=/; expires='
                    . time2str( 5000 + time ),
            ]
        );
        $fake_res->request( GET 'http://localhost/' );
        $jar->extract_cookies($fake_res);

        $jar->extract_cookies($res);
        ok !$jar->get_cookies('http://localhost/')->{metacpan_secure},
            '... and the session was expired';
    };

TODO: {
        local $TODO = 'Write identities tests';
    }
};

done_testing;
