package MetaCPAN::Web::Controller::Mirrors;

use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $location;
    my @protocols;
    if ( my $q = $req->parameters->{q} ) {
        my @parts = split(/\s+/, $q);
        foreach my $part(@parts) {
            push(@protocols, $part) if(grep { $_ eq $part } qw(http ftp rsync));
        }
        if($q =~ /loc\:([^\s]+)/) {
            $location = [ split( /,/, $1 ) ];
        }
    }
    
    my @or;
    push(@or, 
         { not => { filter => { missing =>  { field => $_ } } } })
        for(@protocols);

    my $cv = AE::cv;
    $self->model->get(
        '/mirror/_search',
        {  size   => 999,
           query  => { match_all => {} },
           @or ? ( filter => {
               and => \@or
           } ) : (),
           $location
           ? (
               sort => {
                         _geo_distance => {
                                 location => [ $location->[1], $location->[0] ],
                                 order
                                  => "asc",
                                 unit => "km"
                         } }
             ) : () }
      )->(
        sub {
            my ($data) = shift->recv;
            my $latest = [ map { { %{$_->{_source}}, distance => $_->{sort}->[0] } } @{ $data->{hits}->{hits} } ];
            $cv->send(
                       { mirrors => $latest,
                         took    => $data->{took},
                         total   => $data->{hits}->{total} } );
        } );
    return $cv;
}

1;
