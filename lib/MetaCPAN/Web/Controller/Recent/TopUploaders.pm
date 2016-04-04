package MetaCPAN::Web::Controller::Recent::TopUploaders;
use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub weekly : Local {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['weekly'] );
}

sub monthly : Local {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['monthly'] );
}

sub yearly : Local {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['yearly'] );
}

sub all : Local {
    my ( $self, $c ) = @_;
    $c->forward( 'topuploaders', ['all'] );
}

sub topuploaders : Private {
    my ( $self, $c, $range ) = @_;

    my $data = $c->model('API::Release')->topuploaders($range)->recv;
    my $counts = { map { $_->{term} => $_->{count} }
            @{ $data->{aggregations}{author}{terms} } };
    my $authors = $c->model('API::Author')->get( keys %$counts )->recv;
    $c->stash(
        {
            authors => [
                sort { $b->{releases} <=> $a->{releases} } map {
                    {
                        %{ $_->{_source} },
                            releases => $counts->{ $_->{_source}->{pauseid} }
                    }
                } @{ $authors->{hits}{hits} }
            ],
            took     => $data->{took},
            total    => $data->{aggregations}{author}{total},
            template => 'recent/topuploaders.html',
            range    => $range,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
