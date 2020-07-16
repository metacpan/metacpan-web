package MetaCPAN::Web::Model::API::Module;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API::File';
with 'MetaCPAN::Web::Role::RiverData';

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
    $self->request( "/search/autocomplete/suggest",
        undef, { q => $query, size => 50 } )->transform(
        done => sub {
            my $data = shift;
            return { results => $data->{suggestions} };
        }
        );
}

sub search_web {
    my ( $self, $query, $from, $page_size ) = @_;
    $self->request( "/search/web", undef,
        { q => $query, size => $page_size // 20, from => $from // 0 } )
        ->then( $self->add_river( sub { @{ $_[0]{results} || [] } } ) );
}

sub first {
    my ( $self, $query ) = @_;
    $self->request( "/search/first", undef, { q => $query } )->transform(
        done => sub {
            my $data = shift;
            return unless $data;
            return $data->{documentation};
        }
    );
}

sub requires {
    my ( $self, $module, $page, $page_size, $sort ) = @_;

    $self->request(
        "/reverse_dependencies/module/$module",
        undef,
        {
            page      => $page,
            page_size => $page_size,
            sort      => $sort,
        },
    )->transform(
        done => sub {
            my ($data) = @_;

            # api should really be returning in this form already
            $data->{releases} ||= delete $data->{data} || [];
            $data->{total}    ||= 0;
            $data->{took}     ||= 0;
            return $data;
        }
    )->then( $self->add_river );
}

__PACKAGE__->meta->make_immutable;

1;
