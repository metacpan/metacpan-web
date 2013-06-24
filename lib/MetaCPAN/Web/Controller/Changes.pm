package MetaCPAN::Web::Controller::Changes;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub distribution : Chained('/') Local Args(1) {
    my ( $self, $c, $distribution ) = @_;

    $c->forward('get', [$distribution]);
}

sub release : Chained('/') Local Args(2) {
    my ( $self, $c, $author, $release ) = @_;

    # force consistent casing in URLs
    if ( $author ne uc($author) ) {
        $c->res->redirect(
            $c->uri_for($c->action, [ uc($author), $release ]),
            301
        );
        $c->detach();
    }

    $c->forward('get', [$author, $release]);
}

sub get : Private {
    my ($self, $c, @args) = @_;

    my $file = $c->model('API::Changes')->get(@args)->recv;

        $c->stash({ file => $file });
        $c->forward('/source/content');

}

1;
