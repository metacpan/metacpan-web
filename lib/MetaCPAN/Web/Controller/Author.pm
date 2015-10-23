package MetaCPAN::Web::Controller::Author;

use Moose;
use Data::Pageset;
use List::Util                ();
use DateTime::Format::ISO8601 ();
use namespace::autoclean;
use Locale::Country ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

# Capture the PAUSE id in the root of the chain so we handle the upper-case redirect once.
# Later actions in the chain can get the pauseid out of the stash.
sub root : Chained('/') PathPart('author') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    # force consistent casing in URLs
    if ( $id ne uc($id) ) {

        # NOTE: This only works as long as we only use CaptureArgs
        # and end the chain with PathPart('') and Args(0)
        # (recommended by mst on #catalyst). If we deviate from that
        # we may have to just do substitution on $req->uri
        # because $c->req->args won't be what we expect.
        # Just forget that Args exists (jedi hand wave).

        my $captures = $c->req->captures;
        $captures->[0] = uc $captures->[0];

        $c->res->redirect(
            $c->uri_for( $c->action, $captures, $c->req->params ),
            301,    # Permanent
        );
        $c->detach;
    }

    $c->stash( { pauseid => $id } );
}

# /author/*
sub index : Chained('root') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $id = $c->stash->{pauseid};

    my $author_cv = $c->model('API::Author')->get($id);

    my $releases_cv = $c->model('API::Release')->latest_by_author($id);

    my ( $author, $data ) = ( $author_cv->recv, $releases_cv->recv );
    $c->detach('/not_found') unless ( $author->{pauseid} );

    my $took  = $data->{took};
    my $faves = [];

    if ( $author->{user} ) {
        my $faves_data
            = $c->model('API::Favorite')->by_user( $author->{user} )->recv;
        $took += $faves_data->{took} || 0;

        my @all_fav = map { $_->{fields}->{distribution} }
            @{ $faves_data->{hits}->{hits} };
        my $noLatest = $c->model('API::Release')->no_latest(@all_fav);

        $faves = [
            map {
                my $distro = $_->{fields}->{distribution};
                $noLatest->{$distro} ? () : $_->{fields};
            } @{ $faves_data->{hits}->{hits} }
        ];
        $self->single_valued_arrayref_to_scalar($faves);
        $faves = [ sort { $b->{date} cmp $a->{date} } @{$faves} ];
    }

    my $releases = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    $self->single_valued_arrayref_to_scalar($releases);
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
            took        => $took,
            total       => $data->{hits}->{total},
            template    => 'author.html'
        }
    );

    $c->stash( author_country_name =>
            Locale::Country::code2country( $author->{country} ) )
        if $author->{country};
}

# /author/*/releases
sub releases : Chained('root') PathPart Args(0) {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $id        = $c->stash->{pauseid};
    my $page_size = $req->get_page_size(100);

    my $page = $req->page > 0 ? $req->page : 1;
    my $author_cv = $c->model('API::Author')->get($id);
    my $releases_cv
        = $c->model('API::Release')->all_by_author( $id, $page_size, $page );

    my ( $author, $releases ) = ( $author_cv->recv, $releases_cv->recv );
    $c->detach('/not_found') unless ( $author->{pauseid} );

    my @releases = map { $_->{fields} } @{ $releases->{hits}->{hits} };

    my $pageset = Data::Pageset->new(
        {
            total_entries    => $releases->{hits}->{total},
            entries_per_page => $page_size,
            current_page     => $page,
            pages_per_set    => 10,
            mode             => 'slide'
        }
    );

    $c->stash(
        {
            releases  => \@releases,
            author    => $author,
            pageset   => $pageset,
            page_size => $page_size,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
