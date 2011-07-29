package MetaCPAN::Web::Controller::Author;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $author_cv = $c->model('API')->author->get($id);
    my $releases_cv = $c->model('API')->release->latest_by_author($id);

    my ( $author, $releases ) = ( $author_cv & $releases_cv )->recv;
    $c->detach('/not_found') unless ( $author->{pauseid} );

    $c->stash(
        {   author => $author,
            releases =>
                [ map { $_->{fields} } @{ $releases->{hits}->{hits} } ],
            took     => $releases->{took},
            total    => $releases->{hits}->{total},
            template => 'author.html'
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
