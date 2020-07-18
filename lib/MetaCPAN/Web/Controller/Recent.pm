package MetaCPAN::Web::Controller::Recent;
use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $page      = $req->page;
    my $page_size = $req->get_page_size(100);

    my $filter = $req->params->{f} || 'l';
    my ($data)
        = $c->model('API::Release')->recent( $page, $page_size, $filter )
        ->get;

    $c->add_surrogate_key( 'RECENT', 'DIST_UPDATES' );
    $c->browser_max_age('1m');
    $c->cdn_max_age('1y');    # DIST_UPDATES will purge it

    my $pageset = Data::Pageset->new( {
        current_page     => $page,
        entries_per_page => $page_size,
        mode             => 'slide',
        pages_per_set    => 10,
        total_entries    => $data->{total},
    } );

    $c->stash( {
        recent    => $data->{releases},
        took      => $data->{took},
        page      => $page,
        page_size => $page_size,
        pageset   => $pageset,
        filter    => $filter,
        template  => 'recent.tx',
    } );
}

sub favorites : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/favorite/recent', 301 );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
