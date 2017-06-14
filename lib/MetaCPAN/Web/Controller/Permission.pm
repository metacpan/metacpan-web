package MetaCPAN::Web::Controller::Permission;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub author : Local Args(1) {
    my ( $self, $c, $pause_id ) = @_;

    $c->forward( 'get', $c, [ 'author', $pause_id ] );
}

sub distribution : Local Args(1) {
    my ( $self, $c, $distribution ) = @_;

    $c->forward( 'get', $c, [ 'distribution', $distribution ] );
}

sub module : Local Args(1) {
    my ( $self, $c, $module ) = @_;

    $c->forward( 'get', $c, [ 'module', $module ] );
}

sub get : Private {
    my $self = shift;
    my $c    = shift;
    my ( $type, $name ) = @_;

    my $perms = $c->model('API::Permission')->get( $type, $name )->get;

    if ( !$perms ) {
        $c->stash(
            {
                message => 'Permissions not found for ' . $name
            }
        );
        $c->detach('/not_found');
    }

    $c->stash( { search_term => $name, permission => $perms } );
}

__PACKAGE__->meta->make_immutable;

1;
