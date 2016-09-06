package MetaCPAN::Web::Controller::Recent;
use Moose;

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $page_size = $req->get_page_size(100);

    my ($data)
        = $c->model('API::Release')
        ->recent( $req->page, $page_size, $req->params->{f} || 'l' )->recv;
    my $latest = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    single_valued_arrayref_to_scalar($latest);

    $c->add_surrogate_key('RECENT');
    $c->browser_max_age('1m');
    $c->cdn_max_age('1m');    # tough to paging for now

    $c->stash(
        {
            recent    => $latest,
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
