package MetaCPAN::Web::Controller::Recent::TopUploaders;
use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub weekly : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['weekly'] );
}

sub monthly : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['monthly'] );
}

sub yearly : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['yearly'] );
}

sub all : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['all'] );
}

sub topuploaders : Private {
    my ( $self, $c, $range ) = @_;

    my $data = $c->model('API::Release')->topuploaders($range)->get;

    my $authors
        = $c->model('API::Author')->get_multiple( keys %{ $data->{counts} } )
        ->get;

    $c->stash( {
        authors => [
            sort { $b->{releases} <=> $a->{releases} }
                map +{ %{$_}, releases => $data->{counts}{ $_->{pauseid} } },
            @{ $authors->{authors} }
        ],
        took     => $data->{took},
        total    => $data->{total},
        range    => $range,
        template => 'recent/topuploaders.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
