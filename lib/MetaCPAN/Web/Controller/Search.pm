package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Plack::Response;

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    unless ($req->param('q') or
            $req->param('lucky')) {
        $c->res->redirect('/');
        $c->detach;
    }

    my $query = join(" ", $req->param('q'));

    # translate Foo/Bar.pm to Foo::Bar
    if( $query =~ m{.pm\b} ) {
        $query =~ s{/}{::}g;
        $query =~ s{\.pm\b}{};
    }

    my $model = $c->model('API::Module');
    my $from  = ( $req->page - 1 ) * 20;
    if ( $req->parameters->{lucky} ) {
        my $module = $model->first($query)->recv;
        $c->detach('/not_found') unless ($module);
        $c->res->redirect("/module/$module");
        $c->detach;
    }
    else {
        my $user = $c->user_exists ? $c->user->id : undef;

        $query =~ s{author:([a-zA-Z]*)}{author:\U$1\E};
        $query =~ s/dist(ribution)?:(\w+)/file.distribution:$2/;

        my $results
            = $query =~ /distribution:/
            ? $model->search_distribution( $query, $from, $user )
            : $model->search_collapsed( $query, $from, $user );

        my $authors = $c->model('API::Author')->search( $query, $from );
        ( $results, $authors ) = ( $results->recv, $authors->recv );
        $c->stash(
            { %$results, authors => $authors, template => 'search.html' } );
    }
}

1;
