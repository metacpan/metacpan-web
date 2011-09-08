package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('module') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;
    my $data
        = @module == 1
        ? $c->model('API::Module')->find(@module)->recv
        : $c->model('API::Module')->get(@module)->recv;

    $c->detach('/not_found') unless ( $data->{name} );
    my $pod = $c->model('API')->request( '/pod/' . join( '/', @module ) );
    my $release
        = $c->model('API::Release')->get( $data->{author}, $data->{release} );
    my $author = $c->model('API::Author')->get( $data->{author} );
    my $versions
        = $c->model('API::Release')->versions( $data->{distribution} );
    my $favorites
        = $c->model('API::Favorite')
        ->get( $c->user_exists ? $c->user->id : undef,
        $data->{distribution} );
    my $rating = $c->model('API::Rating')->get( $data->{distribution} );
    ( $pod, $author, $release, $versions, $rating, $favorites )
        = ( $pod & $author & $release & $versions & $rating & $favorites )->recv;
    $data->{myfavorite} = $favorites->{myfavorites}->{ $data->{distribution} };
    $data->{favorites}  = $favorites->{favorites}->{ $data->{distribution} };

    $c->stash(
        {   module  => $data,
            author  => $author,
            pod     => $pod->{raw},
            release => $release->{hits}->{hits}->[0]->{_source},
            rating  => $rating->{ratings}->{ $data->{distribution} },
            versions =>
                [ map { $_->{fields} } @{ $versions->{hits}->{hits} } ],
            template => 'module.html',
        }
    );
}

1;
