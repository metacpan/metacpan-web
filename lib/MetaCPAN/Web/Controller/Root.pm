package MetaCPAN::Web::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => q{} );

=head1 NAME

MetaCPAN::Web::Controller::Root - Root Controller for MetaCPAN::Web

=head1 DESCRIPTION

=head1 METHODS

=head2 auto

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    if ( my $token = $c->token ) {
        $c->authenticate( { token => $token } );
    }
    return 1;
}

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('homepage');
    $c->res->header(
        'Cache-Control' => 'max-age=' . $c->cdn_times->{one_hour} );
    $c->cdn_cache_ttl( $c->cdn_times->{one_year} );

    $c->stash->{template} = 'home.html';
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->forward('/not_found');
}

sub not_found : Private {
    my ( $self, $c ) = @_;
    $c->stash(
        {
            template => 'not_found.html',
            search   => [ @{ $c->req->args }, @{ $c->req->captures } ],
        }
    );
    $c->response->status(404);
}

sub forbidden : Private {
    my ( $self, $c ) = @_;
    $c->stash( { template => 'forbidden.html' } );
    $c->response->status(403);
}

sub robots : Path("robots.txt") : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('robots');
    $c->res->header(
        'Cache-Control' => 'max-age=' . $c->cdn_times->{one_day} );
    $c->cdn_cache_ttl( $c->cdn_times->{one_year} );

    $c->stash( { template => 'robots.txt' } );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    # Pass through to the front end
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        $c->stash->{PLACK_ENV} = 'development';
    }
    $c->stash->{req}                 = $c->req;
    $c->stash->{web_secure}          = $c->config->{web_secure};
    $c->stash->{mcpan_web}           = $c->config->{mcpan_web};
    $c->stash->{mcpan_api}           = $c->config->{mcpan_api};
    $c->stash->{api_secure}          = $c->config->{api_secure};
    $c->stash->{api_external_secure} = $c->config->{api_external_secure}
        || $c->stash->{api_secure};
    $c->stash->{oauth_prefix}
        = $c->stash->{api_external_secure}
        . '/oauth2/authorize?client_id='
        . $c->config->{consumer_key};

    $c->stash->{site_alert_message} = $c->config->{site_alert_message};

    $c->fastly_magic();

}

=head1 AUTHOR

Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
