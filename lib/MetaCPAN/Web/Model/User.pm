package MetaCPAN::Web::Model::User;
use strict;
use warnings;
use base 'MetaCPAN::Web::Model';

sub get {
    my ( $self, $msid ) = @_;
    $self->request( "/user", undef, { msid => $msid } );

}

1;
