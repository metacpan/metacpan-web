package MetaCPAN::Web::Controller::Account::Turing;

use Moose;
use Captcha::reCAPTCHA;
BEGIN { extends 'MetaCPAN::Web::Controller' }

has public_key => ( is => 'ro', required => 1 );

sub index : Path('') {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' ) {
        my $params = $c->req->params;
        my $res    = $c->model("API::User")->turing(
            @$params{qw(recaptcha_challenge_field recaptcha_response_field)},
            $c->token
        )->recv;
        $c->stash(
            {   success => $res->{looks_human},
                error   => $res->{error},
                res     => $res,
                referer => $params->{r},
            }
        );
    }
    $c->stash(
        {   template => 'account/turing.html',
            captcha  => Captcha::reCAPTCHA->new->get_html( $self->public_key, undef, 1 ),
        }
    );

}

__PACKAGE__->meta->make_immutable;
