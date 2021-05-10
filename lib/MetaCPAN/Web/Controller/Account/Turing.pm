package MetaCPAN::Web::Controller::Account::Turing;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

has public_key => ( is => 'ro', required => 1 );

sub index : Path('') : Args(0) {
    my ( $self, $c ) = @_;
    my $user = $c->user
        or $c->detach('/forbidden');

    if ( $c->req->method eq 'POST' ) {
        my $params = $c->req->params;
        my $res    = $user->turing( $params->{'g-recaptcha-response'} )->get;
        $c->stash( {
            success => $res->{looks_human},
            error   => $res->{error},
            res     => $res,
            referer => $params->{r},
        } );
    }
    $c->stash( {
        template      => 'account/turing.tx',
        recaptcha_key => $self->public_key,
    } );

}

__PACKAGE__->meta->make_immutable;

1;
