package MetaCPAN::Web::Authentication::Realm;
use Moose;

extends qw(Catalyst::Authentication::Realm);

has session_key => (
    is     => 'ro',
    writer => '_set_session_key',
);
has expire_on_logout => (
    is     => 'ro',
    writer => '_set_expire_on_logout',
);

around new => sub {
    my ( $orig, $class ) = ( shift, shift );
    my ( $name, $config, $c ) = @_;
    my $self = $class->$orig(@_);
    $self->_set_session_key( $config->{session_key} // 'token' );
    $self->_set_expire_on_logout( $config->{expire_session_on_logout} // 1 );
    return $self;
};

sub persist_user {
    my ( $self, $c, $user ) = @_;
    $c->req->session->set( $self->session_key => $user->for_session );
}

sub remove_persisted_user {
    my ( $self, $c ) = @_;
    if ( $self->expire_on_logout ) {
        $c->req->session->expire;
    }
    else {
        $c->req->session->remove( $self->session_key );
    }
}

sub user_is_restorable {
    my ( $self, $c ) = @_;
    my $key = $c->req->session->get( $self->session_key );
    return $key;
}

around failed_user_restore => sub {
    my ( $orig, $self ) = ( shift, shift );
    $self->$orig(@_);

    # failed restore is not an error
    return 1;
};

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
