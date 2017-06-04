package MetaCPAN::Web::Controller::Favorite;
use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub recent : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $page_size = $c->req->get_page_size(100);
    my $data
        = $c->model('API::Favorite')->recent( $c->req->page, $page_size );
    $c->stash(
        {
            header          => 1,
            show_clicked_by => 1,
            recent          => $data->{favorites},
            took            => $data->{took},
            total           => $data->{total},
            page_size       => $page_size,
            template        => 'favorite/recent.html',
        }
    );
}

sub leaderboard : Local : Args(0) {
    my ( $self, $c ) = @_;

    my $data = $c->model('API::Favorite')->leaderboard();
    return unless $data;

    $c->stash(
        {
            leaders  => $data->{leaderboard},
            took     => $data->{took},
            total    => $data->{total},
            template => 'favorite/leaderboard.html',
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
