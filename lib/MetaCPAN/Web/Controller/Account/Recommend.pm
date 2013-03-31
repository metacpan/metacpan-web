package MetaCPAN::Web::Controller::Account::Recommend;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub recommend : Path('/account/recommend') :Args(3) {
    # FIXME clean up the relation
    my ( $self, $c, $module, undef, $alternative ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    my $model = $c->model('API::User');
    my $res = $model->recommend_alternative( $module => $alternative, $c->token )->recv;
    
    if ( $c->req->looks_like_browser ) {
        $c->res->redirect( $res->{error}
            ? $c->req->referer
            : $c->uri_for('/account/turing/index') );
    }
    else {
        $c->stash( { success => $res->{error} ? \0 : \1 } );
        $c->res->code(400) if($res->{error});
        $c->detach( $c->view('JSON') );
    }
}

__PACKAGE__->meta->make_immutable;
