package MetaCPAN::Web::Controller::Searchauthors;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Plack::Response;

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $query = join( " ", $req->param('q') );

    my $model = $c->model('API::Author');
    my $from  = ( $req->page - 1 ) * 20;

    my $user = $c->user_exists ? $c->user->id : undef;

    $query =~ s{author:([a-zA-Z]*)}{author:\U$1\E}g;

    my $authors = $c->model('API::Author')->search( $query, $from );
    $authors = $authors->recv;

    # changes to be made to this logic.
    if ( !$authors->{total} ) {
        my $suggest = $query;
        $suggest =~ s/:+/::/g;
        if ( $suggest ne $query ) {
            $c->stash(
                {
                    suggest => $suggest,
                }
            );
        }    # changes to be made.
        $c->stash( template => 'no_result.html' );
        $c->detach;
    }

    $c->stash(
        {
            authors  => $authors,
            template => 'searchauthors.html'
        }
    );

}

1;
