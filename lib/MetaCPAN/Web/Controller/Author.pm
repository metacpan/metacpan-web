package MetaCPAN::Web::Controller::Author;

use Moose;
use Data::Pageset;
use List::Util                ();
use DateTime::Format::ISO8601 ();
use namespace::autoclean;
use Locale::Country ();

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

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
        $took += $noLatest->{took} || 0;

        $faves = [
            map {
                my $distro = $_->{fields}->{distribution};
                $noLatest->{no_latest}->{$distro} ? () : $_->{fields};
            } @{ $faves_data->{hits}->{hits} }
        ];
        single_valued_arrayref_to_scalar($faves);
        $faves = [ sort { $b->{date} cmp $a->{date} } @{$faves} ];
    }

    my $releases = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    single_valued_arrayref_to_scalar($releases);
    my $date = List::Util::max
        map { DateTime::Format::ISO8601->parse_datetime( $_->{date} ) }
        @$releases;
    $c->res->last_modified($date) if $date;

    my ( $aggregated, $latest ) = @{ $self->_calc_aggregated($releases) };

    $c->stash(
        {
            aggregated => $aggregated,
            author     => $author,
            faves      => $faves,
            latest     => $latest,
            releases   => $releases,
            template   => 'author.html',
            took       => $took,
            total      => $data->{hits}->{total},
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

    my @releases = map { single_valued_arrayref_to_scalar( $_->{fields} ) }
        @{ $releases->{hits}->{hits} };

    $c->stash(
        {
            author    => $author,
            page_size => $page_size,
            releases  => \@releases,
        }
    );

    return unless $releases->{hits}->{total};

    my $pageset = Data::Pageset->new(
        {
            current_page     => $page,
            entries_per_page => $page_size,
            mode             => 'slide',
            pages_per_set    => 10,
            total_entries    => $releases->{hits}->{total},
        }
    );
    $c->stash( { pageset => $pageset } );
}

sub _calc_aggregated {
    my ( $self, $releases ) = @_;

    my @aggregated;
    my $latest = $releases->[0];
    my $last;

    for my $rel ( @{$releases} ) {
        my ( $canon_rel, $canon_lat ) = map {
            DateTime::Format::ISO8601->parse_datetime($_)
                ->strftime("%Y%m%d%H%M%S")
        } ( $rel->{date}, $latest->{date} );
        $latest = $rel if $canon_rel > $canon_lat;

        next if $last and $last eq $rel->{distribution};
        $last = $rel->{distribution};
        next unless $rel->{name};
        push @aggregated, $rel;
    }

    return [ \@aggregated, $latest ];
}

__PACKAGE__->meta->make_immutable;

1;
