package MetaCPAN::Web::Controller::Release;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use List::Util ();

sub index : PathPart('release') : Chained('/') : Args {
    my ( $self, $c, $author, $release ) = @_;
    my $model = $c->model('API')->release;

    my $data
        = $author && $release
        ? $model->get( $author, $release )
        : $model->find($author);
    my $out = $data->recv->hits->[0]->{_source};
    $c->detach('/not_found') unless ($out);
    ( $author, $release ) = ( $out->{author}, $out->{name} );
    my $modules = $model->modules( $author, $release );
    my $root = $model->root_files( $author, $release );
    my $versions = $model->versions( $out->{distribution} );
    $author = $c->model('API')->author->get($author);
    my $favorites
        = $c->model('API')
        ->favorite->get( $c->user_exists ? $c->user->pause_id : undef,
        $out->{distribution} );
    ( $modules, $versions, $author, $root, $favorites )
        = ( $modules & $versions & $author & $root & $favorites )->recv;
    $out->{myfavorite} = $favorites->{myfavorites}->{ $out->{distribution} };
    $out->{favorites}  = $favorites->{favorites}->{ $out->{distribution} };

    $c->stash(
        {   template => 'release.html',
            release  => $out,
            author   => $author,
            total    => $modules->total,
            took     => List::Util::max(
                $modules->took, $root->took, $versions->took
            ),
            root => [ sort { $a->{name} cmp $b->{name} } @{ $root->fields } ],
            versions => $versions->fields,
            files    => [
                map {
                    {
                        %$_,
                            module   => $_->{'_source.module'},
                            abstract => $_->{'_source.abstract'}
                    }
                    } @{ $modules->fields }
            ]
        }
    );
}

1;
