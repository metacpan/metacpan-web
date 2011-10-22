package MetaCPAN::Web::Controller::Favorite;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';


sub recent : Path('/favorite/recent') {
    my ( $self, $c ) = @_;
    my $cv = AE::cv();
    $c->model('API::Favorite')->recent( $c->req->page )->(
        sub {
            my ($data) = shift->recv;
            my $latest = [ map { $_->{_source} } @{ $data->{hits}->{hits} } ];
            $cv->send(
                {   recent => $latest, took => $data->{took},
                    total  => $data->{hits}->{total}
                }
            );
        }
    );
    $c->stash({%{$cv->recv}, template => 'favorite/recent.html'});
}

sub index : Path('/favorite/leaderboard') {
    my ( $self, $c ) = @_;
    my $cv = AE::cv();
    $c->model( 'API::Favorite' )->leaderboard( $c->req->page )->(
        sub {
            my ( $data ) = shift->recv;
            $cv->send(
                {   leaders => $data->{facets}->{leaderboard}->{terms},
                    took    => $data->{took},
                    total   => $data->{hits}->{total}
                }
            );
        }
    );
    $c->stash( { %{ $cv->recv }, template => 'favorite/leaderboard.html' } );
}

1;
