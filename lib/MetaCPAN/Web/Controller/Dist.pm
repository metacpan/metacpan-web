package MetaCPAN::Web::Controller::Dist;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub root : Chained('/') PathPart('dist') CaptureArgs(1) {
    my ( $self, $c, $dist ) = @_;
    $c->stash( { distribution_name => $dist } );
}

__PACKAGE__->meta->make_immutable;

1;
