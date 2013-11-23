package MetaCPAN::Web::Controller::Lab;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub lab : Local : Path('/lab') {
    my ( $self, $c ) = @_;
    $c->stash( template => 'lab.html' );
}

;1

