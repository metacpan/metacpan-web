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

    my $data = $c->model('API::Release')->topuploaders($range);

    my $authors
        = $c->model('API::Author')->get( keys %{ $data->{counts} } )->get;

    $c->stash(
        {
            authors => [
                sort { $b->{releases} <=> $a->{releases} } map {
                    {
                        %{ $_->{_source} },
                            releases =>
                            $data->{counts}{ $_->{_source}->{pauseid} }
                    }
                } @{ $authors->{hits}{hits} }
            ],
            took     => $data->{took},
            total    => $data->{total},
            template => 'recent/topuploaders.html',
            range    => $range,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
