package MetaCPAN::Web::Controller::Author;

use Moose;
use Data::Pageset             ();
use DateTime::Format::ISO8601 ();
use List::Util                qw( max );
use Locale::Country           ();
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# Capture the PAUSE id in the root of the chain so we handle the upper-case redirect once.
# Later actions in the chain can get the pauseid out of the stash.
sub root : Chained('/') PathPart('author') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    # force consistent casing in URLs
    if ( $id ne uc($id) ) {

        $c->browser_max_age('1y');
        $c->cdn_max_age('1y');

        my @captures = @{ $c->req->captures };
        $captures[0] = uc $id;

        $c->res->redirect(
            $c->uri_for(
                $c->action,               \@captures,
                @{ $c->req->final_args }, $c->req->params,
            ),
            301
        );
        $c->detach;
    }

    $c->add_author_key($id);
    $c->stash( { pauseid => $id } );
}

# /author/*
sub index : Chained('root') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $pauseid = $c->stash->{pauseid};

    my $author_info = $c->model('API::Author')->get($pauseid)->get;
    $c->detach('/not_found')
        if $author_info->{code} && $author_info->{code} == 404;
    my $author = $author_info->{author};

    my $releases = $c->model('API::Release')->latest_by_author($pauseid)->get;

    my $date = max
        map { DateTime::Format::ISO8601->parse_datetime( $_->{date} ) }
        @{ $releases->{releases} };
    $c->res->last_modified($date) if $date;

    my $faves
        = $c->model('API::Favorite')->by_user( $author->{user} )->get;

    my $profiles = $c->model('API::Author')->profile_data;

    my $took = $releases->{took};

    # Show only the 10 most recent releases and favorites on the author page.
    my @recent_releases = sort {
        DateTime::Format::ISO8601->parse_datetime( $b->{date} )
            <=> DateTime::Format::ISO8601->parse_datetime( $a->{date} )
    } @{ $releases->{releases} };
    my @display_releases = splice( @recent_releases, 0, 10 );

    my @recent_faves = sort {
        DateTime::Format::ISO8601->parse_datetime( $b->{date} )
            <=> DateTime::Format::ISO8601->parse_datetime( $a->{date} )
    } @{$faves};
    my @display_faves = splice( @recent_faves, 0, 10 );

    $c->stash( {
        author      => $author,
        faves       => \@display_faves,
        faves_total => scalar @{$faves},
        releases    => \@display_releases,
        profiles    => $profiles,
        took        => $took,
        total    => $releases->{total} // scalar @{ $releases->{releases} },
        template => 'author.tx',
    } );

    $c->stash( author_country_name =>
            Locale::Country::code2country( $author->{country} ) )
        if $author->{country};
}

# /author/*/latest
sub latest_releases : Chained('root') PathPart('latest') Args(0) {
    my ( $self, $c ) = @_;

    my $id = $c->stash->{pauseid};

    my $author_cv = $c->model('API::Author')->get($id);
    my $releases  = $c->model('API::Release')->latest_by_author($id)->get;

    my $author_info = $author_cv->get;
    $c->detach('/not_found')
        if $author_info->{code} && $author_info->{code} == 404;

    my $profiles = $c->model('API::Author')->profile_data;

    $c->stash( {
        author   => $author_info->{author},
        profiles => $profiles,
        total    => $releases->{total} // scalar @{ $releases->{releases} },
        releases => $releases->{releases},
    } );
}

# /author/*/favorites
sub favorites : Chained('root') PathPart Args(0) {
    my ( $self, $c ) = @_;

    my $id = $c->stash->{pauseid};

    my $author_info = $c->model('API::Author')->get($id)->get;
    $c->detach('/not_found')
        if $author_info->{code} && $author_info->{code} == 404;
    my $author = $author_info->{author};

    my $profiles = $c->model('API::Author')->profile_data;

    # Issue: https://github.com/metacpan/metacpan-web/issues/3235
    # Explicitly setting size to 500 to override the default size 250.
    my $size = 500;
    my $faves
        = $c->model('API::Favorite')->by_user( $author->{user}, $size )->get;

    $c->stash( {
        author   => $author,
        faves    => $faves,
        profiles => $profiles,
    } );
}

# /author/*/releases
sub releases : Chained('root') PathPart Args(0) {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $id        = $c->stash->{pauseid};
    my $page_size = $req->get_page_size(100);

    my $page      = $req->page;
    my $author_cv = $c->model('API::Author')->get($id);
    my $releases
        = $c->model('API::Release')
        ->all_by_author( $id, $page, $page_size )
        ->get;

    my $author_info = $author_cv->get;
    $c->detach('/not_found')
        if $author_info->{code} && $author_info->{code} == 404;

    my $profiles = $c->model('API::Author')->profile_data;

    my $pageset = Data::Pageset->new( {
        current_page     => $page,
        entries_per_page => $page_size,
        mode             => 'slide',
        pages_per_set    => 10,
        total_entries    => $releases->{total} // 0,
    } );

    $c->stash( {
        author   => $author_info->{author},
        profiles => $profiles,
        total    => $releases->{total},
        releases => $releases->{releases},
        pageset  => $pageset,
    } );

    return unless $releases->{total};

    $c->stash( { pageset => $pageset } );
}

__PACKAGE__->meta->make_immutable;

1;
