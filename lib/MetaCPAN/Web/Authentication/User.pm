package MetaCPAN::Web::Authentication::User;

use Moose;
use MetaCPAN::Web::Types qw(HashRef ArrayToHash);

extends 'Catalyst::Authentication::User';

has token      => ( is => 'ro' );
has raw_data   => ( is => 'ro' );
has user_model => ( is => 'ro' );

sub from_session {
    my ( $class, $c, $token ) = @_;
    my $data = $c->model('API::User')->get($token)->get;
    return undef
        if !$data->{id};
    $class->new(
        $c,
        {
            raw_data => $data,
            token    => $token,
        }
    );
}

sub find_user {
    my ( $class, $auth, $c ) = @_;
    my $data = $c->model('API::User')->login($auth)->get;
    return
        unless $data->{access_token};
    $class->from_session( $c, $data->{access_token} );
}

sub BUILDARGS {
    my ( $self, $c, $args ) = @_;
    return {
        user_model => $c->model('API::User'),
        %{ $args->{raw_data} },
        %$args,
    };
}

sub for_session { $_[0]->token }

has id             => ( is => 'ro' );
has looks_human    => ( is => 'ro' );
has passed_captcha => ( is => 'ro' );
has access_token   => ( is => 'ro' );
has identity       => (
    is     => 'ro',
    isa    => HashRef->plus_coercions( ArrayToHash ['name'] ),
    coerce => 1,
);
has pause_id => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_pause_id',
);

sub _build_pause_id {
    my $self    = shift;
    my $ident   = $self->identity;
    my ($pause) = grep { $_->{name} eq 'pause' } @$ident;
    $pause && $pause->{key};
}

for my $method ( qw(
    delete_identity
    update_profile
    get_profile
    add_favorite
    remove_favorite
    turing
) )
{
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        $self->user_model->$method( $self->token, @_ );
    };
}

__PACKAGE__->meta->make_immutable;

1;
