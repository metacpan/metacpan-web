package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

use URI ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub login_root : Chained('/') : PathPart('login') : CaptureArgs(0) { }

sub index : Chained('login_root') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    my $req = $c->req;

    if ( my $code = $req->parameters->{code} ) {
        $c->authenticate($code);
        my $state = $c->req->params->{state} || q{};
        $c->res->redirect( $c->uri_for("/$state") );
    }
    else {
        $c->stash( {
            success  => $req->parameters->{success},
            error    => $req->parameters->{error},
            template => 'account/login.tx',
        } );
    }
}

sub openid : Chained('login_root') : PathPart : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    my $model = $c->model('API::User');
    $c->stash( {
        consumer_key => $model->consumer_key,
        openid_url   => $model->openid_url,
    } );
}

sub pause : Chained('login_root') : PathPart : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    my $model = $c->model('API::User');
    $c->stash( {
        oauth_url    => $model->oauth_url,
        consumer_key => $model->consumer_key,
    } );
}

sub login : Chained('login_root') : PathPart('') : Args(1) {
    my ( $self, $c, $choice ) = @_;

    my $model = $c->model('API::User');
    my $url   = URI->new( $model->oauth_url );
    $url->query_form( {
        client_id => $model->consumer_key,
        choice    => $choice,
    } );

    $c->res->redirect( $url->as_string );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
