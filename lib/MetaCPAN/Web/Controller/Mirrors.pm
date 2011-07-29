package MetaCPAN::Web::Controller::Mirrors;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;
    my $location;
    my @protocols;
    if ( my $q = $req->parameters->{q} ) {
        my @parts = split( /\s+/, $q );
        foreach my $part (@parts) {
            push( @protocols, $part )
                if ( grep { $_ eq $part } qw(http ftp rsync) );
        }
        if ( $q =~ /loc\:([^\s]+)/ ) {
            $location = [ split( /,/, $1 ) ];
        }
    }

    my $cv   = AE::cv;
    my $data = $c->model('API')->mirror->list($location, \@protocols)->recv;
    my $latest = [
        map {
            {
                %{ $_->{_source} }, distance => $location
                    ? $_->{sort}->[0]
                    : undef
            }
            } @{ $data->hits }
    ];
    $c->stash(
        {   mirrors  => $latest,
            took     => $data->took,
            total    => $data->total,
            template => 'mirrors.html',
        }
    );
}

1;
