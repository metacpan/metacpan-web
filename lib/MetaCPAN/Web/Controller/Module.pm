package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub root : Chained('/') PathPart('module') CaptureArgs(1) {
    my ( $self, $c, $module ) = @_;
    $c->stash( { module_name => $module } );
}

sub pod : Chained('root') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    my $module = $c->stash->{module_name};
    $c->cdn_max_age('1y');
    $c->res->redirect( $c->uri_for( '/pod', $module ), 301 );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
