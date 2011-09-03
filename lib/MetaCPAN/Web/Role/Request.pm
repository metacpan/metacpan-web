package MetaCPAN::Web::Role::Request;

use Moose::Role;
use Plack::Session;

sub page {
    my $page = shift->parameters->{p};
    return $page && $page =~ /^\d+$/ ? $page : 1;
}

sub session {
    my $self = shift;
    return Plack::Session->new( $self->env );
}

1;
