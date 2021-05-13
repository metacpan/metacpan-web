package MetaCPAN::Web::Controller::About;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('ABOUT');
    $c->add_surrogate_key('STATIC');
    $c->browser_max_age('1d');
    $c->cdn_max_age('1y');
}

sub about : Path : Args(0) {
    my ( $self, $c ) = @_;
}

sub contributors : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub contact : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub meta_hack : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub resources : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/about/contact', 301 );
    $c->detach;
}

sub sponsors : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub development : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub missing_modules : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub faq : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub metadata : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub stats : Local : Args(0) {
    my ( $self, $c ) = @_;

    # Sorry PITA to maintain
    $c->res->redirect( '/about/', 301 );
}

__PACKAGE__->meta->make_immutable;

1;
