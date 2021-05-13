package MetaCPAN::Web::Controller::Tools;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub tools : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( {
        template => 'tools.tx',
    } );
}

__PACKAGE__->meta->make_immutable;
1;
