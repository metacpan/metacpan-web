package MetaCPAN::Web::Controller::Search::AutoComplete;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    my $req   = $c->req;
    my $model = $c->model('API')->module;
    my $query = join( ' ', $req->param('q') );
    $query =~ s/::/ /g if ($query);

    my $data = $model->autocomplete($query)->recv;
    $c->res->content_type('application/json');
    $c->res->body( JSON::encode_json( $data->{results} ) );
}

1;
