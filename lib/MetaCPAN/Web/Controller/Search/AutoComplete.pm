package MetaCPAN::Web::Controller::Search::AutoComplete;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use JSON;
use Plack::Response;

sub index {
    my ( $self, $req ) = @_;

    my $cv = AE::cv;

    my $model = $self->model('Module');
    my $query = join( ' ', $req->parameters->get_all('q') );
    $query =~ s/::/ /g if ($query);

    my $cond = $model->search_collapsed( $query, 0 );

    $cond->cb(
        sub {
            my ($data) = shift->recv;

            my $result
                = [ map { { module => $_->[0]->{documentation} } }
                    @{ $data->{results} || [] } ];

            my $response = Plack::Response->new(
                200,
                [ 'Content-Type' => 'application/json', ],
                [ JSON::encode_json($result) ]
            );

            $cv->send($response);
        }
    );

    return $cv;
}

1;
