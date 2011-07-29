package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('module') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;
    my $data
        = @module == 1
        ? $c->model('API')->module->find(@module)->recv
        : $c->model('API')->module->get(@module)->recv;

    $c->detach('/not_found') unless ( $data->{name} );
    my $pod = $c->model('API')->request( '/pod/' . join( '/', @module ) );
    my $release
        = $c->model('API')->release->get( $data->{author}, $data->{release} );
    my $author = $c->model('API')->author->get( $data->{author} );
    my $versions
        = $c->model('API')->release->versions( $data->{distribution} );
    my $favorites
        = $c->model('API')->favorite
        ->get( $c->user_exists ? $c->user->pause_id : undef,
        $data->{distribution} );
    ( $pod, $author, $release, $versions, $favorites )
        = ( $pod & $author & $release & $versions & $favorites )->recv;
    $data->{myfavorite} = $favorites->{myfavorites}->{ $data->{distribution} };
    $data->{favorites}  = $favorites->{favorites}->{ $data->{distribution} };

    $c->stash(
        {   module   => $data,
            author   => $author,
            pod      => $pod->{raw},
            release  => $release->hits->[0]->{_source},
            versions => $versions->fields,
            template => 'module.html',
        }
    );
}

1;
