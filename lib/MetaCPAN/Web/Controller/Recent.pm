package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index : Path {
    my ( $self, $c ) = @_;
    my $cv = AE::cv();
    $c->model('API::Release')->recent( $c->req->page )->(
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
    $c->stash({%{$cv->recv}, template => 'recent.html'});
}

1;
