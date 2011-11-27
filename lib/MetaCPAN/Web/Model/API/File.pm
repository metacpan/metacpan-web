package MetaCPAN::Web::Model::API::File;
use Moose;
extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/file/' . join( '/', @path ) );
}

sub source {
    my ( $self, @path ) = @_;
    $self->request( '/source/' . join( '/', @path ), undef, { raw => 1 } );
}

sub dir {
    my ( $self, $author, $release, @path ) = @_;

    $self->request(
        '/file',
        {   query => {
                filtered => {
                    query  => { match_all => {}, },
                    filter => {
                        and => [
                            { term => { 'file.level' => scalar @path } },
                            { term => { 'file.author' => $author } },
                            { term => { 'file.release' => $release } },
                            {   prefix => {
                                    'file.path' => join( '/', @path, undef )
                                }
                            },
                        ]
                    },
                }
            },
            size => 999,
            fields => [qw(name stat.mtime path file.stat.size file.directory slop documentation mime)],
        }
    );
}

1;
