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

    my $cv = AE::cv;
    my $start
        = DateTime->now->truncate( to => 'month' )->subtract( months => 23 );
    my $activity = $c->model('API')->request(
        '/release/_search', {
            query  => { match_all => {} },
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
    );
    $activity->(
        sub {
            my $entries = shift->recv->{facets}->{histo}->{entries};
            my $data    = { map { $_->{time} => $_->{count} } @$entries };
            my $line    = [
                map {
                    $data->{ $start->clone->add( months => $_ )->epoch
                            . '000' }
                        || 0
                    } ( 0 .. 23 )
            ];
            $cv->send( { data => $line } );
        }
    );
    $c->res->content_type('image/svg+xml');
    $c->stash({%{$cv->recv}, template => 'activity.xml'});
    $c->detach('View::Raw');

}

1;
