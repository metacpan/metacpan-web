package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ($self, $req) = @_;
    my $cv = AE::cv;
    $self->model('/release/_search', {
        size => 100,
        query => { match_all => {} },
        sort => [{ 'date' => { order => "desc" } }]
    })->(sub {
        my ($data) = shift->recv;
        my $latest = [map { $_->{_source} } @{$data->{hits}->{hits}}];
        $cv->send({ recent => $latest, took =>$data->{took}, total => $data->{hits}->{total} });
    });
    return $cv;
}

1;