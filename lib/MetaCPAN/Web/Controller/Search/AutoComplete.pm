package MetaCPAN::Web::Controller::Search::AutoComplete;

use Moose;
use JSON::MaybeXS ();
use namespace::autoclean;
use MetaCPAN::Web::Util qw( fix_structure );

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    my $model = $c->model('API::Module');
    my $query = join( q{ }, $c->req->param('q') );
    my $data  = $model->autocomplete($query)->recv;
    $c->res->content_type('application/json');
    $c->res->body(
        JSON::MaybeXS::encode_json(
            $self->single_valued_arrayref_to_scalar( $data->{results} )
        )
    );
}

__PACKAGE__->meta->make_immutable;

1;
