package MetaCPAN::Web::Controller::Search;

use strict;
use warnings;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use Ref::Util qw( is_arrayref );

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $page      = $req->page;
    my $page_size = $req->get_page_size(20);

    # Redirect back to main page if search query is empty irrespective of
    # whether we're feeling lucky or not.
    unless ( $req->param('q') ) {
        $c->res->redirect(q{/});
        $c->detach;
    }

    my $query = join( q{ }, $req->param('q') );
    $c->stash( { search_query => $query } );

    if ( $query eq '{searchTerms}' ) {

        # url is being used directly from opensearch plugin
        $c->res->redirect(q{/});
        $c->detach;
    }

    # translate Foo/Bar.pm to Foo::Bar
    if ( $query =~ m{.pm\b} ) {
        $query =~ s{/}{::}g;
        $query =~ s{\.pm\b}{};
    }

    $query =~ s/^\s+//;
    $query =~ s/\s+$//;

    my $model = $c->model('API::Module');
    my $from  = ( $page - 1 ) * $page_size;
    if (
        $req->parameters->{lucky}
        or

        # DuckDuckGo-like syntax for bangs that redirect to the first
        # result.
        $query =~ s[^ (?: \\ | ! ) ][]x
        )
    {
        my $module = $model->first($query)->get;
        $module = $module->[0] if $module and is_arrayref($module);
        if ( $module && $module eq $query ) {
            $c->res->redirect( $c->uri_for( '/pod', $module ) );
            $c->detach;
        }
        else {
            my $author = $c->model('API::Author')->search($query)->get;
            if (   $author->{total} == 1
                && $query eq $author->{authors}->[0]->{pauseid} )
            {
                $c->res->redirect( $c->uri_for( '/author', uc($query) ) );
                $c->detach;
            }
            elsif ($module) {
                $c->res->redirect( $c->uri_for( '/pod', $module ) );
                $c->detach;
            }
            else {
                $c->detach('/not_found') unless ($module);
            }
        }
    }
    else {
        my ( $results, $authors ) = Future->needs_all(
            $model->search_web( $query, $from, $page_size ),
            $c->model('API::Author')->search( $query, $from ),
        )->get;

        if ( !$results->{total} && !$authors->{total} ) {
            my $suggest = $query;
            $suggest =~ s/\s*:+\s*/::/g;
            if ( $suggest ne $query ) {
                $c->stash( {
                    suggest => $suggest,
                } );
            }
            $c->stash( {
                template => 'no_result.tx',
            } );
            $c->detach;
        }

        my $pageset = Data::Pageset->new( {
            current_page     => $page,
            entries_per_page => $page_size,
            mode             => 'slide',
            pages_per_set    => 10,
            total_entries    => $results->{total},
        } );

        $c->stash( {
            %$results,
            single_dist => !$results->{collapsed},
            authors     => $authors,
            pageset     => $pageset,
            template    => 'search.tx',
        } );
    }
}

__PACKAGE__->meta->make_immutable;

1;
