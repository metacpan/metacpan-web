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
    my @fixed_data = map { fix_structure($_) } @{ $data->{results} };
    $c->res->content_type('application/json');
    $c->res->body( JSON::MaybeXS::encode_json( \@fixed_data ) );
}

1;
