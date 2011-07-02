package MetaCPAN::Web::Controller::Account::Settings;

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
