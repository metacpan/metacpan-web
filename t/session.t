use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;
use MIME::Base64;
use Try::Tiny;
use URI::Escape;

{
    package    ## no critic (Package)
        MetaCPAN::Web::Controller::TestSession;
    use Moose;
    BEGIN { extends 'MetaCPAN::Web::Controller'; }

    sub index : Path {
        my ( $self, $c ) = @_;
        if ( my $flavor = $c->req->param('flavor') ) {
            $c->req->session->set( flavor => $flavor );
        }
        $c->res->body('yum');
    }
}

test_psgi app, sub {
    my $cb = shift;

    subtest 'verify cookie handling' => sub {
        my $url = q[/testsession];

        my $cookie = get_cookie( $cb, $url );

        my $biscuit = get_cookie( $cb, "$url?flavor=snickerdoodle", $cookie );

        isnt $cookie, $biscuit, 'cookie has been baked';

        is get_cookie( $cb, $url, $biscuit ), $biscuit, q[cookie preserved];

        isnt get_cookie( $cb, $url ), $biscuit, q[cookie has been eaten :'(];

        my $spoiled = $biscuit;
        is get_cookie( $cb, $url, $biscuit ), $biscuit, q[cookie is back];

        $spoiled =~ s/:([^:])/:=/;    # Chew cookie.
        isnt get_cookie( $cb, $url, $spoiled ), $spoiled, q[cookie went bad];

        $spoiled = $biscuit;
        $spoiled =~ s/(.)$/=/;        # Chew signature.
        isnt get_cookie( $cb, $url, $spoiled ), $spoiled, q[siggy went bad];
    };

};

sub get_cookie {
    my ( $cb, $url, $send_cookie ) = @_;
    my $req = HTTP::Request->new(
        GET => $url,
        [
            Cookie => $send_cookie,
        ]
    );
    ok( my $res = $cb->($req), $url );
    is( $res->code, 200, 'code 200' )
        or diag $res->content;

    my $cookie = URI::Escape::uri_unescape(
        ( $res->header('set-cookie') =~ /([^;]+)/ )[0] );

    like $cookie, qr/:\w+[=]{0,2}:/, 'looks like cookie';

    #diag $cookie;

    return $cookie;
}
done_testing;
