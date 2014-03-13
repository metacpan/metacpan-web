package MetaCPAN::Web::Controller::Author;

use Moose;
use Data::Pageset;
use List::Util                ();
use DateTime::Format::ISO8601 ();
use namespace::autoclean;
use Locale::Country ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(1) {
    my ( $self, $c, $id ) = @_;

    # force consistent casing in URLs
    if ( $id ne uc($id) ) {
        $c->res->redirect( '/author/' . uc($id), 301 );
        $c->detach;
    }

    my $author_cv = $c->model('API::Author')->get($id);

    my $releases_cv = $c->model('API::Release')->latest_by_author($id);

    my ( $author, $data ) = ( $author_cv->recv, $releases_cv->recv );
    $c->detach('/not_found') unless ( $author->{pauseid} );

    my $faves_cv = $c->model('API::Favorite')->by_user( $author->{user} );

    my $faves_data = $faves_cv->recv;
    my $faves      = [
        sort { $b->{date} cmp $a->{date} }
        map  { $_->{fields} } @{ $faves_data->{hits}{hits} }
    ];

    my $releases = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    my $date = List::Util::max
        map { DateTime::Format::ISO8601->parse_datetime( $_->{date} ) }
        @$releases;
    $c->res->last_modified($date) if $date;

    $c->stash(
        {
            author      => $author,
            releases    => $releases,
            faves       => $faves,
            show_author => 1,
            took        => $data->{took} + ( $faves_data->{took} || 0 ),
            total       => $data->{hits}->{total},
            template    => 'author.html'
        }
    );

    $c->stash( author_country_name =>
            Locale::Country::code2country( $author->{country} ) )
        if $author->{country};
}

sub releases : Path : Args(2) {
    my ( $self, $c, $id, $foo ) = @_;

    my $size      = 100;
    my $page      = $c->req->page > 0 ? $c->req->page : 1;
    my $author_cv = $c->model('API::Author')->get($id);
    my $releases_cv
        = $c->model('API::Release')
        ->all_by_author( $id, $size, $c->req->page );

    my ( $author, $releases ) = ( $author_cv->recv, $releases_cv->recv );

    my @releases = map { $_->{fields} } @{ $releases->{hits}->{hits} };

    my $pageset = Data::Pageset->new(
        {
            total_entries    => $releases->{hits}->{total},
            entries_per_page => $size,
            current_page     => $page,
            pages_per_set    => 10,
            mode             => 'slide'
        }
    );

    $c->stash(
        {
            releases => \@releases,
            author   => $author,
            pageset  => $pageset,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
