package MetaCPAN::Web::Controller::Login;

use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $code = $req->parameters->{code};
    return $self->not_found($req) unless ($code);

    my $cv = AE::cv;
    $self->model->request("/login/validate?code=$code")->(
        sub {
            my $data = shift->recv;
            $req->session->set(msid => $data->{sid});
            my $res = $req->new_response;
            $res->redirect('/');
            $cv->send($res);
        }
    );
    return $cv;
}

1;
