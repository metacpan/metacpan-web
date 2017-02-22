package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    if ( my $code = $c->req->parameters->{code} ) {
        my $data = $c->model('API')->request(
            '/oauth2/access_token',
            undef,
            {
                client_id     => $c->config->{consumer_key},
                client_secret => $c->config->{consumer_secret},
                code          => $code,
            },
        )->recv;
        $c->req->session->set( token => $data->{access_token} );
        $c->authenticate( { token => $data->{access_token} } );
        my $state = $c->req->params->{state} || q{};
        $c->res->redirect( $c->uri_for("/$state") );
    }
    else {
        $c->stash( { template => 'account/login.html' } );
    }
}

sub openid : Local : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    $c->stash( { template => 'account/openid-login.html' } );
}

__PACKAGE__->meta->make_immutable;

1;
