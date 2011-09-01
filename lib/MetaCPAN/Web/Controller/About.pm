package MetaCPAN::Web::Controller::About;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub contributors : Path('contributors') {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/contributors.html' );
}

1;
