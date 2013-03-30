package MetaCPAN::Web::Model::API::Recommendation;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $user, $module ) = @_;
    my $cv = $self->cv;
    $self->request(
        '/recommendation/_search',
        {   size  => 0,
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [
                            map {
                                { term => { 'recommendation.module' => $_ } }
                                } $module
                        ]
                    }
                }
            },
            facets => {
                instead_of => {
                    terms => {
                        field => 'recommendation.instead_of',
                    },
                },
            }
        }
        )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {   took      => $data->{took},
                    instead_of => {
                        map { $_->{term} => $_->{count} }
                            @{ $data->{facets}->{instead_of}->{terms} }
                    }
                },
            );
        }
        );
    return $cv;
}

sub get_supplanted {
    my ( $self, $user, $module ) = @_;
    my $cv = $self->cv;
    $self->request(
        '/recommendation/_search',
        {   size  => 0,
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [
                            map {
                                { term => { 'recommendation.instead_of' => $_ } }
                                } $module
                        ]
                    }
                }
            },
            facets => {
                supplanted_by => {
                    terms => {
                        field => 'recommendation.module',
                    },
                },
            }
        }
        )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {   took      => $data->{took},
                    supplanted_by => {
                        map { $_->{term} => $_->{count} }
                            @{ $data->{facets}{supplanted_by}{terms} }
                    }
                },
            );
        }
        );
    return $cv;
}


__PACKAGE__->meta->make_immutable;
