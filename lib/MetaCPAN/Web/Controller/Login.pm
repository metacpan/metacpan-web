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

__PACKAGE__->meta->make_immutable;

1;
