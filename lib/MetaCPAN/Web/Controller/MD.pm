package MetaCPAN::Web::Controller::MD;

use Moose;

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub view : Private {
    my ( $self, $c, $author, $release, @path ) = @_;

    my $source = $c->model('API::File')->source( $author, $release, @path );

    $c->stash( {
        source   => $source->get->{raw},
        template => 'md.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
