package MetaCPAN::Web::Controller::Favorite;
use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub recent : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $page      = $c->req->page;
    my $page_size = $c->req->get_page_size(100);
    my $data = $c->model('API::Favorite')->recent( $page, $page_size )->get;

    my $pageset = Data::Pageset->new( {
        current_page     => $page,
        entries_per_page => $page_size,
        mode             => 'slide',
        pages_per_set    => 10,
        total_entries    => $data->{total},
    } );

    $c->stash( {
        header          => 1,
        show_clicked_by => 1,
        recent          => $data->{favorites},
        took            => $data->{took},
        pageset         => $pageset,
        template        => 'favorite/recent.html',
        favorite_type   => 'recent',
    } );
}

sub leaderboard : Local : Args(0) {
    my ( $self, $c ) = @_;

    my $data = $c->model('API::Favorite')->leaderboard->get;
    return unless $data;

    $c->stash( {
        leaders       => $data->{leaderboard},
        took          => $data->{took},
        total         => $data->{total},
        template      => 'favorite/leaderboard.html',
        favorite_type => 'leaderboard',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
