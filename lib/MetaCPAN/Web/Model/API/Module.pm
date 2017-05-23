package MetaCPAN::Web::Model::API::Module;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API::File';

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

=head1 NAME

MetaCPAN::Web::Model::Module - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Moritz Onken, Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub find {
    my ( $self, @path ) = @_;
    $self->request( '/module/' . join( q{/}, @path ) );
}

sub autocomplete {
    my ( $self, $query ) = @_;
    my $cv = $self->cv;
    $self->request( "/search/autocomplete", undef,
        { q => $query, size => 50 } )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {
                    results => [
                        map { $_->{fields} } @{ $data->{hits}->{hits} || [] }
                    ]
                }
            );
        }
        );
    return $cv;
}

sub search_web {
    my ( $self, $query, $from, $page_size ) = @_;
    my $cv = $self->cv;
    $self->request( "/search/web", undef,
        { q => $query, size => $page_size // 20, from => $from // 0 } )->cb(
        sub {
            my $data = shift->recv;
            $cv->send($data);
        }
        );
    return $cv;
}

sub first {
    my ( $self, $query ) = @_;
    my $cv = $self->cv;
    $self->request( "/search/simple", undef, { q => $query } )->cb(
        sub {
            my ($result) = shift->recv;
            return $cv->send(undef) unless ( $result->{hits}->{total} );
            $cv->send(
                $result->{hits}->{hits}->[0]->{fields}->{documentation} );
        }
    );
    return $cv;
}

sub requires {
    my ( $self, $module, $page, $page_size, $sort ) = @_;
    $sort ||= { date => 'desc' };
    my $cv = $self->cv;
    $self->request(
        '/release/_search',
        {
            query => {
                bool => {
                    must => [
                        { term => { 'status'     => 'latest' } },
                        { term => { 'authorized' => 1 } },
                        {
                            term => {
                                'dependency.module' => $module
                            }
                        }
                    ]
                }
            },
            size => $page_size,
            from => $page * $page_size - $page_size,
            sort => [$sort],
        }
        )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {
                    data =>
                        [ map { $_->{_source} } @{ $data->{hits}->{hits} } ],
                    total => $data->{hits}->{total},
                    took  => $data->{took}
                }
            );
        }
        );
    return $cv;
}

__PACKAGE__->meta->make_immutable;

1;
