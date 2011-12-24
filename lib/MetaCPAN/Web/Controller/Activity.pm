package MetaCPAN::Web::Controller::Activity;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use DateTime;

my %res = ( week => '1w', month => 'month' );

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;
    my $res = $res{ $req->parameters->{res} || 'week' } || '1w';

    my $q = [];
    if ( my $author = $req->parameters->{author} ) {
        push( @$q, { term => { author => uc($author) } } );
    }
    if ( my $distribution = $req->parameters->{distribution} ) {
        push( @$q, { term => { distribution => $distribution } } );
    }
    if ( my $requires = $req->parameters->{requires} ) {
        push( @$q, { term => { "release.dependency.module" => $requires } } );
    }
    if ( $req->parameters->{f} eq 'n' ) {
        push(
            @$q,
            @{  $c->model('API::Release')
                    ->_new_distributions_query->{constant_score}->{filter}
                    ->{and}
                }
        );
    }

    my $start
        = DateTime->now->truncate( to => 'month' )->subtract( months => 23 );
    my $data = $c->model('API')->request(
        '/release/_search',
        {   query  => { match_all => {} },
            facets => {
                histo => {
                    date_histogram => { field => 'date', interval => $res },
                    facet_filter   => {
                        and => [
                            {   range => {
                                    date => { from => $start->epoch . '000' }
                                }
                            },
                            @$q
                        ]
                    }
                }
            },
            size => 0,
        }
    )->recv;
    my $entries = $data->{facets}->{histo}->{entries};
    $data = { map { $_->{time} => $_->{count} } @$entries };
    my $line = [
        map {
            $data->{ $start->clone->add( months => $_ )->epoch . '000' }
                || 0
            } ( 0 .. 23 )
    ];
    $c->res->content_type('image/svg+xml');
    $c->res->headers->expires( time + 86400 );
    $c->stash( { data => $line, template => 'activity.xml' } );
    $c->detach('View::Raw');

}

1;
