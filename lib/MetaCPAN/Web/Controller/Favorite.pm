package MetaCPAN::Web::Controller::Favorite;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index : Path('/recent/favorites') {
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
    $c->stash({%{$cv->recv}, template => 'recent/favorite.html'});
}

1
