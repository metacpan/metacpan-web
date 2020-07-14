package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

has consumer_key    => ( is => 'ro' );
has consumer_secret => ( is => 'ro' );

sub COMPONENT {
    my ( $class, $app, $args ) = @_;
    my $config = $class->merge_config_hashes(
        {
            consumer_key    => $app->config->{consumer_key},
            consumer_secret => $app->config->{consumer_secret},
        },
        $args,
    );
    return $class->SUPER::COMPONENT( $app, $config );
}

sub index : Path : Args(0) {
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

sub openid : Local : Args(0) {
    my ( $self, $c ) = @_;

    # Never cache at CDN
    $c->cdn_never_cache(1);

    $c->stash( {
        consumer_key => $self->consumer_key,
        template     => 'account/openid-login.html',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
