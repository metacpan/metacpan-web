package MetaCPAN::Web::Controller::Account;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index {
    my ( $self, $req ) = @_;

    my $cv = AE::cv;
    $cv->send({});
    return $cv;
}

1;
