package MetaCPAN::Web::Model::API::Rating;
use Moose;
use namespace::autoclean;
use Future;

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

use List::Util qw(uniq);

sub get {
    my ( $self, @distributions ) = @_;
    @distributions = uniq @distributions;

    # If there are no distributions this will build a query with an empty
    # filter and ES will return a parser error... so just skip it.
    if ( !@distributions ) {
        return Future->done( {} );
    }

    return $self->request(
        '/rating/_search',
        {
            size  => 0,
            query => {
                terms => { distribution => \@distributions }
            },
            aggregations => {
                ratings => {
                    terms => {
                        field => 'distribution'
                    },
                    aggregations => {
                        ratings_dist => {
                            stats => {
                                field => 'rating'
                            }
                        }
                    }
                }
            }
        }
        )->transform(
        done => sub {
            my $data = shift;
            return {
                took    => $data->{took},
                ratings => {
                    map { $_->{key} => $_->{ratings_dist} }
                        @{ $data->{aggregations}->{ratings}->{buckets} }
                }
            };
        }
        );
}

__PACKAGE__->meta->make_immutable;

1;
