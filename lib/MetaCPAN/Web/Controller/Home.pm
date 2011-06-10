package MetaCPAN::Web::Controller::Home;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub endpoint {'/'}

sub index {
    my ( $self, $req ) = @_;
    if ( $req->path ne '/' ) {
        my $cv = AE::cv;
        $cv->send( $self->not_found($req) );
        return $cv;
    }
    return $self->next::method($req);
}

1;
