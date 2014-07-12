package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Plack::Response;

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    # Redirect back to main page if search query is empty irrespective of
    # whether we're feeling lucky or not.
    unless ( $req->param('q') ) {
        $c->res->redirect('/');
        $c->detach;
    }

    my $query = join( " ", $req->param('q') );

    # translate Foo/Bar.pm to Foo::Bar
    if ( $query =~ m{.pm\b} ) {
        $query =~ s{/}{::}g;
        $query =~ s{\.pm\b}{};
    }

    my $model = $c->model('API::Module');
    my $from  = ( $req->page - 1 ) * 20;
    if (
        $req->parameters->{lucky}
        or

        # DuckDuckGo-like syntax for bangs that redirect to the first
        # result.
        $query =~ s[^ (?: \\ | ! ) ][]x
        )
    {
        my $module = $model->first($query)->recv;
        $c->detach('/not_found') unless ($module);
        $c->res->redirect("/pod/$module");
        $c->detach;
    }
    else {
        my $user = $c->user_exists ? $c->user->id : undef;

        # these would be nicer if we had variable-length lookbehinds...
        $query =~ s{(^|\s)author:([a-zA-Z]+)(?=\s|$)}{$1author:\U$2\E}g;
        $query
            =~ s/(^|\s)dist(ribution)?:([\w-]+)(?=\s|$)/$1file.distribution:$3/g;
        $query
            =~ s/(^|\s)module:(\w[\w:]*)(?=\s|$)/$1module.name.analyzed:$2/g;

        my $results
            = $query =~ /(distribution|module\.name\S*):/
            ? $model->search_expanded( $query, $from, $user )
            : $model->search_collapsed( $query, $from, $user );

        my @dists = $query =~ /distribution:(\S+)/g;

        my $authors = $c->model('API::Author')->search( $query, $from );
        ( $results, $authors ) = ( $results->recv, $authors->recv );

        # The "total" is actually "total distributions".
        if ( $results->{total} == 1 ) {
            my $dist_files = $results->{results}->[0];

            # There may be more than one file per dist.
            if ( @$dist_files == 1 ) {

                # FIXME: What's the right incantation for this?
                # Is module name better than documentation?
                # We may need to check indexed (in which case we need to make
                # sure it's actually a boolean).
                my $module_name = $dist_files->[0]->{module}->[0]->{name}
                    || $dist_files->[0]->{documentation};

                if ($module_name) {
                    $c->res->redirect("/pod/$module_name");
                    $c->detach;
                }
            }
        }
        elsif ( !$results->{total} && !$authors->{total} ) {
            my $suggest = $query;
            $suggest =~ s/:+/::/g;
            if ( $suggest ne $query ) {
                $c->stash(
                    {
                        suggest => $suggest,
                    }
                );
            }
            $c->stash( template => 'no_result.html' );
            $c->detach;
        }

        $c->stash(
            {
                %$results,
                single_dist => @dists == 1,
                authors     => $authors,
                template    => 'search.html'
            }
        );
    }
}

1;
