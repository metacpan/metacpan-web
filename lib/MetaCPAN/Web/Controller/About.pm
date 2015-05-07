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

sub development : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/development.html' );
}

sub missing_modules : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/missing_modules.html' );
}

sub faq : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/faq.html' );
}

sub metadata : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'about/metadata.html' );
}

__PACKAGE__->meta->make_immutable;

1;
