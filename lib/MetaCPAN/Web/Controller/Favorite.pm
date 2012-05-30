package MetaCPAN::Web::Controller::Favorite;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';


sub recent : Path('/favorite/recent') {
    my ( $self, $c ) = @_;

    my $data = $c->model('API::Favorite')->recent( $c->req->page )->recv;

    $c->stash({
        recent   => [ map { $_->{_source} } @{ $data->{hits}->{hits} } ],
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
