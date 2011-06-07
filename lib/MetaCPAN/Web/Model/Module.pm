package MetaCPAN::Web::Model::Module;
use strict;
use warnings;
use base 'MetaCPAN::Web::Model';

sub find {
  my ( $self, $module ) = @_;
  $self->request(
    '/file/_search',
    { size   => 1,
      query => { filtered => { query  => { match_all => {} },
      filter => {
        and => [
          { term => { 'documentation' => $module } },
          { term => { 'file.indexed'  => \1, } },
          { term => { status          => 'latest', } } ]
      } } },
      sort => [ { 'date' => { order => "desc" } } ] } );
}

sub get {
  my ( $self, @path ) = @_;
  $self->request( '/file/' . join( '/', @path ) );
}

sub source {
  my ( $self, @module ) = @_;
  $self->request( '/source/' . join( '/', @module), undef, { raw => 1 } );
}

1;
