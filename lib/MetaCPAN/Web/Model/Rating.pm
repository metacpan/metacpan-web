package MetaCPAN::Web::Model::Rating;
use strict;
use warnings;
use base 'MetaCPAN::Web::Model';

use List::MoreUtils qw(uniq);

sub get {
    my ( $self, @distributions ) = @_;
    @distributions = uniq @distributions;
    my $cv = $self->cv;
    $self->request(
        '/rating/_search',
        {   size  => 0,
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [
                            map { { term => { 'rating.distribution' => $_ } } }
                              @distributions
                        ] } }
            },
            facets => {
                ratings => {
                    terms_stats => {
                        value_field => 'rating.rating',
                        key_field   => 'rating.distribution'
                    } } } }
      )->(
        sub {
            my ($ratings) = shift->recv;
            $cv->send(
                {   took    => $ratings->{took},
                    ratings => {
                        map { $_->{term} => $_ }
                          @{ $ratings->{facets}->{ratings}->{terms} } } } );
        } );
    return $cv;
}

1;
