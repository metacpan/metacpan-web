package MetaCPAN::Web::Controller;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->meta->make_immutable;
