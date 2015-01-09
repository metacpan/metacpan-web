package MetaCPAN::Web::Controller::Search::AutoComplete;

use Moose;
use JSON::MaybeXS ();
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    my $model = $c->model('API::Module');
    my $query = join( q{ }, $c->req->param('q') );
    my $data  = $model->autocomplete($query)->recv;
    $c->res->content_type('application/json');
    $c->res->body(
        JSON::MaybeXS::encode_json(
            $self->extract_first_element( $data->{results} )
        )
    );
}

1;
