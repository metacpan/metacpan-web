package MetaCPAN::Web::Controller::Root;
use Moose;
use Log::Log4perl::MDC;
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

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('HOMEPAGE');
    $c->browser_max_age('1h');
    $c->cdn_max_age('1y');

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
    $c->cdn_never_cache(1);

    $c->stash( {
        template     => 'not_found.html',
        search_terms => [ @{ $c->req->args }, @{ $c->req->captures } ],
    } );
    $c->response->status(404);
}

sub internal_error : Private {
    my ( $self, $c ) = @_;
    $c->cdn_never_cache(1);

    $c->stash( { template => 'internal_error.html' } );
    $c->response->status(500);
}

sub forbidden : Private {
    my ( $self, $c ) = @_;
    $c->cdn_never_cache(1);

    $c->stash( { template => 'forbidden.html' } );
    $c->response->status(403);
}

sub robots : Path("robots.txt") : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('ROBOTS');
    $c->browser_max_age('1d');
    $c->cdn_max_age('1y');

    $c->stash( { template => 'robots.txt' } );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
