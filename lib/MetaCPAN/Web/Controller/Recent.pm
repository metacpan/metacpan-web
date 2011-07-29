package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index : Path {
    my ( $self, $c ) = @_;
    my $cv = AE::cv;
    $c->model('API')->release->recent( $c->req->page )->(
        sub {
            my ($data) = shift->recv;
            $cv->send(
                {   recent => $data->source,
                    took   => $data->took,
                    total  => $data->total
                }
            );
        }
    );
    $c->stash({%{$cv->recv}, template => 'recent.html'});
}

1;
