package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

use URI ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

has consumer_key    => ( is => 'ro' );
has consumer_secret => ( is => 'ro' );
has openid_url      => ( is => 'ro' );
has oauth_url       => ( is => 'ro' );

sub COMPONENT {
    my ( $class, $app, $args ) = @_;
    my $config = $class->merge_config_hashes(
        {
            consumer_key    => $app->config->{consumer_key},
            consumer_secret => $app->config->{consumer_secret},
            openid_url      =>
                ( $app->config->{api_public} || $app->config->{api} )
                . '/login/openid',
            oauth_url => ( $app->config->{api_public} || $app->config->{api} )
                . '/oauth2/authorize',
        },
        $args,
    );
    return $class->SUPER::COMPONENT( $app, $config );
}

sub login_root : Chained('/') : PathPart('login') : CaptureArgs(0) { }

sub index : Chained('login_root') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    my $req = $c->req;

    if ( my $code = $req->parameters->{code} ) {
        my $data = $c->model('API')->request(
            '/oauth2/access_token',
            undef,
            {
                client_id     => $self->consumer_key,
                client_secret => $self->consumer_secret,
                code          => $code,
            },
        )->get;
        $c->req->session->set( token => $data->{access_token} );
        $c->authenticate( { token => $data->{access_token} } );
        my $state = $c->req->params->{state} || q{};
        $c->res->redirect( $c->uri_for("/$state") );
    }
    else {
        $c->stash( {
            success  => $req->parameters->{success},
            error    => $req->parameters->{error},
            template => 'account/login.html',
        } );
    }
}

sub openid : Chained('login_root') : PathPart : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    $c->stash( {
        consumer_key => $self->consumer_key,
        openid_url   => $self->openid_url,
    } );
}

sub pause : Chained('login_root') : PathPart : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    $c->stash( {
        oauth_url    => $self->oauth_url,
        consumer_key => $self->consumer_key,
    } );
}

sub login : Chained('login_root') : PathPart('') : Args(1) {
    my ( $self, $c, $choice ) = @_;

    my $url = URI->new( $self->oauth_url );
    $url->query_form( {
        client_id => $self->consumer_key,
        choice    => $choice,
    } );

    $c->res->redirect( $url->as_string );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
