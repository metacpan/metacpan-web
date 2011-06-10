package MetaCPAN::Web::Model::Author;
use strict;
use warnings;
use base 'MetaCPAN::Web::Model';

sub get {
    my ( $self, $author ) = @_;
    $self->request( "/author/" . uc($author) );

}

1;
