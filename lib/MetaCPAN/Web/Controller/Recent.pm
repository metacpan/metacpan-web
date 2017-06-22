package MetaCPAN::Web::Controller::Recent;
use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $page_size = $req->get_page_size(100);

    my ($data)
        = $c->model('API::Release')
        ->recent( $req->page, $page_size, $req->params->{f} || 'l' )->get;

    $c->add_surrogate_key( 'RECENT', 'DIST_UPDATES' );
    $c->browser_max_age('1m');
    $c->cdn_max_age('1y');    # DIST_UPDATES will purge it

    $c->stash(
        {
            recent    => $data->{releases},
            took      => $data->{took},
            total     => $data->{hits}->{total},
            template  => 'recent.html',
            page_size => $page_size,
        }
    );
}

sub favorites : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/favorite/recent', 301 );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
