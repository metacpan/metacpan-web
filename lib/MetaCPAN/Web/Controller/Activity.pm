package MetaCPAN::Web::Controller::Activity;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use DateTime;

sub content_type { 'image/svg+xml' }

sub template { 'activity.xml' }

sub raw { 1 }

my %res = ( week => '1w', month => 'month' );

sub index {
    my ($self, $req) = @_;
    my $res = $res{$req->parameters->{res}} || '1w';
    
    my $q = [];
    if(my $author = $req->parameters->{author}) {
        push(@$q, { term => { author => $author }});
    }
    if(my $distribution = $req->parameters->{distribution}) {
        push(@$q, { term => { distribution => $distribution }});
    }
    
    my $cv = AE::cv;
    my $start = DateTime->now->truncate( to => 'month' )->subtract( months => 23 );
    my $activity = $self->model('/release/_search',
    {
        query => { match_all => {} },
        facets => { histo => { date_histogram => { field => 'date', interval => $res },
        facet_filter => { and => [ { range => { date => { from => $start->epoch . '000' }}},
            @$q ] }}},
        size => 0,
    });
    $activity->(
        sub {
            my $entries = shift->recv->{facets}->{histo}->{entries};
            my $data = { map { $_->{time} => $_->{count} } @$entries };
            my $line = [ 
                   map {
                       $data->{ $start->clone->add( months => $_ )->epoch
                             . '000' }
                         || 0
                     } ( 0 .. 23 ) ];
            $cv->send(
                {
                   data => $line } );
        } );

    return $cv;
    
}

1;