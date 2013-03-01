package MetaCPAN::Web::Controller::Author;

use Moose;
use List::Util                ();
use DateTime::Format::ISO8601 ();
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(1) {
    my ( $self, $c, $id ) = @_;

    # force consistent casing in URLs
    if ( $id ne uc( $id ) ) {
        $c->res->redirect( '/author/' . uc( $id ), 301 );
        $c->detach;
    }

    my $author_cv = $c->model( 'API::Author' )->get( $id );

    my $releases_cv = $c->model( 'API::Release' )->latest_by_author($id);

    my ( $author, $data ) = ( $author_cv->recv, $releases_cv->recv );
    $c->detach( '/not_found' ) unless ( $author->{pauseid} );

    my $faves_cv = $c->model( 'API::Favorite' )->by_user($author->{user});

    my $faves_data = $faves_cv->recv;
    my $faves = [ sort { $b->{date} cmp $a->{date} }
            map { $_->{fields} } @{ $faves_data->{hits}{hits} } ];

    my $releases = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    my $date = List::Util::max
        map { DateTime::Format::ISO8601->parse_datetime( $_->{date} ) }
        @$releases;
    $c->res->last_modified( $date );

    $c->stash(
        {   author   => $author,
            releases => $releases,
            faves    => $faves,
            took     => $data->{took} + $faves_data->{took},
            total    => $data->{hits}->{total},
            template => 'author.html'
        }
    );

    $self->twitter_card($c);
}

sub twitter_card :Private {
    my( $self, $c ) = @_;

    my %twitter = (
        card        => 'summary',
        url         => $c->req->uri,
        title       => $c->stash->{author}{name},
        description => 'CPAN Author',
        site        => 'metacpan',
    );

    $twitter{image} = $c->stash->{author}{gravatar_url}
        if $c->stash->{author}{gravatar_url};

    my ( $profile ) = grep { $_->{name} eq 'twitter' } 
        @{ $c->stash->{author}{profile} || [] };

    $twitter{creator} = $profile->{id} if $profile;

    $c->stash( twitter_card => \%twitter );
}


__PACKAGE__->meta->make_immutable;

1;
