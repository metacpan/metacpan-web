package MetaCPAN::Web::Controller::Release;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use List::Util ();

sub index : PathPart('release') : Chained('/') : Args {
    my ( $self, $c, $author, $release ) = @_;
    my $model = $c->model('API::Release');

    my $data
        = $author && $release
        ? $model->get( $author, $release )
        : $model->find($author);
    my $out = $data->recv->{hits}->{hits}->[0]->{_source};
    $c->detach('/not_found') unless ($out);
    ( $author, $release ) = ( $out->{author}, $out->{name} );
    my $modules = $model->modules( $author, $release );
    my $root = $model->root_files( $author, $release );
    my $versions = $model->versions( $out->{distribution} );
    $author = $c->model('API::Author')->get($author);
    my $favorites
        = $c->model('API::Favorite')
        ->get( $c->user_exists ? $c->user->id : undef,
        $out->{distribution} );
    ( $modules, $versions, $author, $root, $favorites )
        = ( $modules & $versions & $author & $root & $favorites )->recv;
    $out->{myfavorite} = $favorites->{myfavorites}->{ $out->{distribution} };
    $out->{favorites}  = $favorites->{favorites}->{ $out->{distribution} };

    my @root_files = (
        sort
        map { $_->{fields}->{name} } @{ $root->{hits}->{hits} }
    );

    my $changes = undef;
    foreach my $filename ( @root_files ) {
        if ( $filename =~ m{\AChange}i ) {
            $changes = $filename;
            last;
        }
    }

    $c->stash(
        {   template => 'release.html',
            release  => $out,
            author   => $author,
            changes  => $changes,
            total    => $modules->{hits}->{total},
            took     => List::Util::max(
                $modules->{took}, $root->{took}, $versions->{took}
            ),
            root => \@root_files,
            versions =>
                [ map { $_->{fields} } @{ $versions->{hits}->{hits} } ],
            files => [
                map {
                    {
                        %{ $_->{fields} },
                            module   => $_->{fields}->{'_source.module'},
                            abstract => $_->{fields}->{'_source.abstract'}
                    }
                    } @{ $modules->{hits}->{hits} }
            ]
        }
    );
}

1;
