package MetaCPAN::Web::Model::API::Rating;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

=head1 NAME

MetaCPAN::Web::Model::Rating - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Moritz Onken, Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use List::MoreUtils qw(uniq);

sub get {
    my ( $self, @distributions ) = @_;
    @distributions = uniq @distributions;
    my $cv = $self->cv;
    $self->request(
        '/rating/_search',
        {
            size  => 0,
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [
                            map {
                                { term => { 'rating.distribution' => $_ } }
                            } @distributions
                        ]
                    }
                }
            },
            facets => {
                ratings => {
                    terms_stats => {
                        value_field => 'rating.rating',
                        key_field   => 'rating.distribution'
                    }
                }
            }
        }
        )->cb(
        sub {
            my ($ratings) = shift->recv;
            $cv->send(
                {
                    took    => $ratings->{took},
                    ratings => {
                        map { $_->{term} => $_ }
                            @{ $ratings->{facets}->{ratings}->{terms} }
                    }
                }
            );
        }
        );
    return $cv;
}
__PACKAGE__->meta->make_immutable;

1;
