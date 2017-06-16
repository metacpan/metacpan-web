package MetaCPAN::Web::Model::API::Module;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API::File';

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
    $self->request( "/search/autocomplete", undef,
        { q => $query, size => 50 } )->transform(
        done => sub {
            my $data = shift;
            return { results =>
                    [ map { $_->{fields} } @{ $data->{hits}->{hits} || [] } ]
            };
        }
        );
}

sub search_web {
    my ( $self, $query, $from, $page_size ) = @_;
    $self->request( "/search/web", undef,
        { q => $query, size => $page_size // 20, from => $from // 0 } );
}

sub first {
    my ( $self, $query ) = @_;
    $self->request( "/search/simple", undef, { q => $query } )->transform(
        done => sub {
            my $data = shift;
            return undef
                unless ( $data->{hits}->{total} );
            return $data->{hits}->{hits}->[0]->{fields}->{documentation};
        }
    );
}

sub requires {
    my ( $self, $module, $page, $page_size ) = @_;

    $self->request(
        "/reverse_dependencies/module/$module",
        undef,
        {
            page      => $page,
            page_size => $page_size,
        },
    );
}

__PACKAGE__->meta->make_immutable;

1;
