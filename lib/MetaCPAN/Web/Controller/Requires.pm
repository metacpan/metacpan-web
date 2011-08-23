package MetaCPAN::Web::Controller::Requires;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Chained('/') : PathPart('requires') : CaptureArgs(0) {
}

sub module : Chained('index') : PathPart : Args(1) {
    my ( $self, $c, $module ) = @_;
    my $cv = AE::cv;
    my $data = $c->model('API::Module')->requires($module, $c->req->page)->recv;
    $c->stash({%{$data}, module => $module, template => 'requires.html'});
}

1;
