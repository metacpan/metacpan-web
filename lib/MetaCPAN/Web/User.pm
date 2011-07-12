package MetaCPAN::Web::User;

use Moose;
extends 'Catalyst::Authentication::User';

use Hash::AsObject;

has obj => ( is => 'rw', isa => 'Hash::AsObject' );

sub get_object { shift->obj }

sub store {'Catalyst::Authentication::Plugin::Store::Proxy'}

sub for_session {
    my $self = shift;
    my ($token) = map { $_->{token} }
        grep { $_->{client} eq 'metacpan' } @{ $self->obj->{identity} };
    return $token;
}

sub from_session {
    my ( $self, $c, $id ) = @_;
    my $user = $c->model('API::User')->get($id)->recv;
    $self->obj( Hash::AsObject->new($user) ) if ($user);
    return $user ? $self : undef;
}

sub find_user {
    my ( $self, $auth, $c ) = @_;
    my $obj = Hash::AsObject->new(
        $c->model('API::User')->get( $auth->{token} )->recv );
    $self->obj( $obj );
    return $self;
}

sub supports {
    my ( $self, @feature ) = @_;
    return 1 if ( grep { $_ eq 'session' } @feature );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
