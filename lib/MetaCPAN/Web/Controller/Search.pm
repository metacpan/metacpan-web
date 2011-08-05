package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Plack::Response;

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;
    my @query = ( $req->param('q'), $req->param('lucky') );

    unless (@query) {
        $c->res->redirect('/');
        $c->detach;
    }

    my $query = join( ' ', @query );
    $query =~ s/::/ /g if ($query);

    my $model = $c->model('API::Module');
    my $from  = ( $req->page - 1 ) * 20;
    if ( $req->parameters->{lucky} ) {
        my $module = $model->first($query)->recv;
        $c->detach('/not_found') unless ($module);
        $c->res->redirect("/module/$module");
        $c->detach;
    }
    else {
        my $pause_id = $c->user ? $c->user->pause_id : undef;
        
        $query =~ s{author:([a-zA-Z]*)}{author:uc($1)}e;
        
        my $results
            = $query =~ /distribution:/
            ? $model->search_distribution( $query, $from, $pause_id )
            : $model->search_collapsed( $query, $from, $pause_id );

        my $authors = $c->model('API::Author')->search( $query, $from );
        ( $results, $authors ) = ( $results->recv, $authors->recv );
        $c->stash(
            { %$results, authors => $authors, template => 'search.html' } );
    }
}

1;
