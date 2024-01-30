package MetaCPAN::Web::Model::API::File;
use Moose;
extends 'MetaCPAN::Web::Model::API';
with 'MetaCPAN::Web::Role::FileData';

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/file/' . join( '/', @path ) )
        ->then( $self->_groom_fileinfo( [], \@path ) );
}

sub source {
    my ( $self, @path ) = @_;
    $self->request( '/source/' . join( '/', @path ), undef, { raw => 1 } );
}

sub dir {
    my ( $self, @path ) = @_;
    my $path = join '/', @path;
    my $data = $self->request("/file/dir/$path")->transform(
        done => sub {
            my $dir = $_[0]->{dir};
            for my $entry (@$dir) {
                my $stat = $entry->{stat} ||= {};
                for my $stat_entry ( map /^stat\.(.*)/ ? $1 : (),
                    keys %$entry )
                {
                    $stat->{$stat_entry}
                        = delete $entry->{"stat.$stat_entry"};
                }
            }
            return $dir;
        }
    )->then( $self->_groom_fileinfo( ['dir'] ) );
}

__PACKAGE__->meta->make_immutable;

1;
