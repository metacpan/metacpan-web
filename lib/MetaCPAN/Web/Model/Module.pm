package MetaCPAN::Web::Model::Module;
use strict;
use warnings;
use base 'MetaCPAN::Web::Model';

sub find {
    my ( $self, $module ) = @_;
    $self->request("/module/$module");
}

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/file/' . join( '/', @path ) );
}

sub source {
    my ( $self, @module ) = @_;
    $self->request( '/source/' . join( '/', @module ), undef, { raw => 1 } );
}

1;
