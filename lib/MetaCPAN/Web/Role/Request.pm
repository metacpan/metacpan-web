package MetaCPAN::Web::Role::Request;

use Moose::Role;
use Plack::Session;

sub page {
    my $page = shift->parameters->{p};
    return $page && $page =~ /^\d+$/ ? $page : 1;
}

sub clone {
    my ( $self, %extra ) = @_;
    return ( ref $self )->new( { %{ $self->env }, %extra } );
}

sub session {
    my $self = shift;
    return Plack::Session->new( $self->env );
}

1;
