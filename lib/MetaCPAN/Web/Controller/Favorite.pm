package MetaCPAN::Web::Controller::Favorite;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub recent : Path('/favorite/recent') {
    my ( $self, $c ) = @_;

    my $data = $c->model( 'API::Favorite' )->recent( $c->req->page )->recv;
    my @faves = map { $_->{_source} } @{ $data->{hits}->{hits} };
    my @user_ids = map { $_->{user} } @faves;

    my $authors
        = $c->model( 'API::Author' )->by_user( \@user_ids )->recv->{hits}
        ->{hits};

    my %author_for_user_id
        = map { $_->{fields}->{user} => $_->{fields}->{pauseid} } @{$authors};

    foreach my $fave ( @faves ) {
        if ( exists $author_for_user_id{ $fave->{user} } ) {
            $fave->{clicked_by_author} = $author_for_user_id{ $fave->{user} };
        }
    }

    $c->stash({
        header   => 1,
        recent   => \@faves,
        took     => $data->{took},
        total    => $data->{hits}->{total},
        template => 'favorite/recent.html',
    });
}

sub index : Path('/favorite/leaderboard') {
    my ( $self, $c ) = @_;

    my $data = $c->model( 'API::Favorite' )->leaderboard( $c->req->page )->recv;
    my @leaders = @{ $data->{facets}->{leaderboard}->{terms} }[ 0 .. 99 ];

    $c->stash({
        leaders  => \@leaders,
        took     => $data->{took},
        total    => $data->{hits}->{total},
        template => 'favorite/leaderboard.html',
    });
}

1;
