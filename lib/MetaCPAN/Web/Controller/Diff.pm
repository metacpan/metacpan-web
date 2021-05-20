package MetaCPAN::Web::Controller::Diff;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub release : Chained('/release/root') PathPart('diff') Args {
    my ( $self, $c, $source_author, $source_release, @path ) = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    $c->forward( 'view',
        [ $source_author, $source_release, $author, $release, @path ] );
}

sub dist : Chained('/dist/root') PathPart('raw') Args {
    my ( $self, $c, $source_author, $source_release, @path ) = @_;
    my $dist    = $c->stash->{distribution_name};
    my $release = $c->model('API::Release')->find($dist)->get->{release}
        or $c->detach('/not_found');
    $c->forward(
        'view',
        [
            $source_author,   $source_release, $release->{author},
            $release->{name}, @path
        ]
    );
}

sub view : Private {
    my ( $self, $c, $source_author, $source_release, $target_author,
        $target_release, @path )
        = @_;

    my $diff;
    if (@path) {
        $diff = $c->model('API::Diff')->files(
            join( '/', $source_author, $source_release, @path ),
            join( '/', $target_author, $target_release, @path ),
        )->get;
    }
    else {
        $diff = $c->model('API::Diff')->releases(
            $source_author, $source_release,
            $target_author, $target_release,
        )->get;
    }
    $c->stash( {
        diff     => $diff,
        template => 'diff.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
