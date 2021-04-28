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
    );
}

__PACKAGE__->meta->make_immutable;

1;
