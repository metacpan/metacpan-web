package MetaCPAN::Web::Controller::Account::Turing;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

has public_key => ( is => 'ro', required => 1 );

sub index : Path('') : Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' ) {
        my $params = $c->req->params;
        my $res    = $c->model('API::User')
            ->turing( $params->{'g-recaptcha-response'}, $c->token, )->get;
        $c->stash( {
            success => $res->{looks_human},
            error   => $res->{error},
            res     => $res,
            referer => $params->{r},
        } );
    }
    $c->stash( {
        template      => 'account/turing.html',
        recaptcha_key => $self->public_key,
    } );

}

__PACKAGE__->meta->make_immutable;

1;
