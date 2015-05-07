package MetaCPAN::Web::Model::API::File;
use Moose;
extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/file/' . join( q{/}, @path ) );
}

sub source {
    my ( $self, @path ) = @_;
    $self->request( '/source/' . join( q{/}, @path ), undef, { raw => 1 } );
}

sub dir {
    my ( $self, $author, $release, @path ) = @_;
    $self->request(
        '/file/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {}, },
                    filter => {
                        and => [
                            { term => { 'file.level'   => scalar @path } },
                            { term => { 'file.author'  => $author } },
                            { term => { 'file.release' => $release } },
                            {
                                prefix => {
                                    'file.path' => join( q{/}, @path, q{} )
                                }
                            },
                        ]
                    },
                }
            },
            size   => 999,
            fields => [
                qw(name stat.mtime path file.stat.size file.directory slop documentation mime)
            ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
