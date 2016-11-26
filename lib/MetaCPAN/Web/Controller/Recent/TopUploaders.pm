package MetaCPAN::Web::Controller::Recent::TopUploaders;
use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub weekly : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['weekly'] );
}

sub monthly : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['monthly'] );
}

sub yearly : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['yearly'] );
}

sub all : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['all'] );
}

sub topuploaders : Private {
    my ( $self, $c, $range ) = @_;
    my $authors = $c->model('API::Release')->topuploaders($range)->recv;
    $c->stash(
        {
            %$authors, template => 'recent/topuploaders.html',
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
