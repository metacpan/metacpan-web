package MetaCPAN::Web::Controller::About;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub about : Local : Path('/about') {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about.html' );
}

sub contributors : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/contributors.html' );
}

sub resources : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/resources.html' );
}

sub sponsors : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/sponsors.html' );
}

1;
