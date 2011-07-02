package MetaCPAN::Web::Controller::Account;

use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;

    my $cv = AE::cv;
    $cv->send({});
    return $cv;
}

1;
