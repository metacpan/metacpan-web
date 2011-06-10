package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    $self->model('Release')->recent( $req->page )->(
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
    return $cv;
}

1;
