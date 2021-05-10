package MetaCPAN::Web::Model::API::User;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

has api_public      => ( is => 'ro' );
has consumer_key    => ( is => 'ro' );
has consumer_secret => ( is => 'ro' );

sub COMPONENT {
    my ( $class, $app, $args ) = @_;
    $args = $class->merge_config_hashes( $class->config, $args );
    $args = $class->merge_config_hashes(
        {
            api             => $app->config->{api},
            consumer_key    => $app->config->{consumer_key},
            consumer_secret => $app->config->{consumer_secret},
        },
        $args,
    );
    $args->{api_public} ||= $args->{api};
    return $class->SUPER::COMPONENT( $app, $args );
}

sub openid_url {
    my ($self) = @_;
    return $self->api_public . '/login/openid';
}

sub oauth_url {
    my ($self) = @_;
    return $self->api_public . '/oauth2/authorize';
}

sub login {
    my ( $self, $code ) = @_;
    return $self->request(
        '/oauth2/access_token',
        undef,
        {
            client_id     => $self->consumer_key,
            client_secret => $self->consumer_secret,
            code          => $code,
        },
    );
}

sub get {
    my ( $self, $token ) = @_;
    $self->request( '/user', undef, { access_token => $token } );
}

sub delete_identity {
    my ( $self, $token, $identity ) = @_;
    $self->request(
        "/user/identity/$identity", undef,
        { access_token => $token }, 'DELETE'
    );
}

sub update_profile {
    my ( $self, $token, $data ) = @_;
    $self->request( '/user/profile', $data,
        { access_token => $token }, 'PUT' );
}

sub get_profile {
    my ( $self, $token ) = @_;
    $self->request( '/user/profile', undef, { access_token => $token } );
}

sub add_favorite {
    my ( $self, $token, $data ) = @_;
    $self->request( '/user/favorite', $data, { access_token => $token } );
}

sub remove_favorite {
    my ( $self, $token, $data ) = @_;
    $self->request( '/user/favorite/' . $data->{distribution},
        undef, { access_token => $token }, 'DELETE' );
}

sub turing {
    my ( $self, $token, $answer ) = @_;
    $self->request(
        '/user/turing',
        { answer       => $answer },
        { access_token => $token },
    );
}

__PACKAGE__->meta->make_immutable;

1;
