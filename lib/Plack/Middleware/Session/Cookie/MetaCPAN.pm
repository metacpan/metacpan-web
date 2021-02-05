package Plack::Middleware::Session::Cookie::MetaCPAN;
use strict;
use parent qw(Plack::Middleware::Session::Cookie);

use Plack::Util;
use MIME::Base64     ();
use Cpanel::JSON::XS ();
use Try::Tiny qw( catch try );

my $json = Cpanel::JSON::XS->new->canonical(1);

sub prepare_app {
    my $self = shift;

    $self->serializer( sub {

        # Pass $_[0] since the json subs may have a ($) protoype.
        # Pass '' to base64 for a blank separator (instead of newlines).
        MIME::Base64::encode( Cpanel::JSON::XS::encode_json( $_[0] ), q[] );
    } ) unless $self->serializer;

    $self->deserializer( sub {

        # We can't reference @_ from inside the try block.
        my ($cookie) = @_;

        # Use try/catch so JSON doesn't barf if the cookie is bad.
        try {
            Cpanel::JSON::XS::decode_json( MIME::Base64::decode($cookie) );
        }

        # No session.
        catch { +{}; };
    } ) unless $self->deserializer;

    $self->SUPER::prepare_app;
    my $wrap = $self->app;
    my $app  = sub {
        my $env     = shift;
        my $session = $env->{'psgix.session'};
        my $options = $env->{'psgix.session.options'};
        $options->{no_store} = 1;
        my $start       = $json->encode($session);
        my $have_cookie = !!$self->state->get_session_id($env);
        Plack::Util::response_cb(
            $wrap->($env),
            sub {
                if ( $start ne $json->encode($session) ) {
                    delete $options->{no_store};
                }
                if ( $have_cookie && !keys %$session ) {
                    delete $options->{no_store};
                    $options->{expire} = 1;
                }
            }
        );
    };
    $self->app($app);
}

sub save_state {
    my $self = shift;
    my ( undef, undef, $env ) = @_;
    return
        if $env->{'psgix.session.options'}{no_store};

    $self->SUPER::save_state(@_);
}

1;
