package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    if ( my $code = $c->req->parameters->{code} ) {
        my $data
            = $c->model('API')
            ->request( '/oauth2/access_token?client_id='
                . $c->config->{consumer_key}
                . '&client_secret='
                . $c->config->{consumer_secret}
                . "&code=$code" )->recv;
        $c->req->session->set( token => $data->{access_token} );
        $c->authenticate( { token => $data->{access_token} } );
        my $state = $c->req->params->{state} || q{};
        $c->res->redirect( $c->uri_for("/$state") );
    }
    elsif ( $c->req->path eq 'login/openid' ) {
        $c->stash( { template => 'account/openid-login.html' } );
    }
    else {
        $c->stash( { template => 'account/login.html' } );
    }
}

use Plack::Middleware::Session::Cookie;

package Plack::Middleware::Session::Cookie;
use strict;
no warnings 'redefine';

# every response contains the Vary: Cookie header
# which will make sure that upstream caches
# and browsers cache the responses based on the
# value in the Cookie header.
# With stock Plack::Middleware::Session::Cookie,
# the cookie will change with every request
# because a random id is generated. This will break
# this very useful feature and the browser and
# upstream caches will revalidate each request.
# Overriding generate_id solves this nicely.
# Since the generated_id is never validated against
# anything, there seems to be no ramification.

sub generate_id {
    'session';
}

1;
