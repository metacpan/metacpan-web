package MetaCPAN::Web::Controller::Badge;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use DateTime;

sub dist : Chained('/dist/root') PathPart('badge.svg') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward( 'badge' );
}

sub badge : Private {
    my ( $self, $c ) = @_;

    $c->res->content_type('image/svg+xml');
    $c->res->headers->expires( time + 86400 );
    $c->stash( {
        template => 'badge.svg.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
