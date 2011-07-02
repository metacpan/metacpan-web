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
    ( $pod, $author, $release, $versions )
        = ( $pod & $author & $release & $versions )->recv;

    $c->stash(
        {   module  => $data,
            author  => $author,
            pod     => $pod->{raw},
            release => $release->{hits}->{hits}->[0]->{_source},
            versions =>
                [ map { $_->{fields} } @{ $versions->{hits}->{hits} } ],
            template => 'module.html',
        }
    );
}

1;
