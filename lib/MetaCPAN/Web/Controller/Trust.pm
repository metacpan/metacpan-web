package MetaCPAN::Web::Controller::Trust;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index : Path('/trust/leaderboard') {
    my ( $self, $c ) = @_;

    my $data    = $c->model('API::Trust')->leaderboard( $c->req->page )->recv;
    my @leaders = @{ $data->{facets}->{leaderboard}->{terms} }[ 0 .. 99 ];
    $c->stash(
        {
            leaders  => \@leaders,
            took     => $data->{took},
            total    => $data->{hits}->{total},
            template => 'trust/leaderboard.html',
        }
    );
}

1;
