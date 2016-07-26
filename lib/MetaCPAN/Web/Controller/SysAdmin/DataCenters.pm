package MetaCPAN::Web::Controller::SysAdmin::DataCenters;

use strict;
use warnings;
use MetaCPAN::Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# This is used by http://mirrors.cpan.org/ fetch our
# datacenters and update the official CPAN list

sub list_datacenters : Path('list') : Args(0) GET {
    my ( $self, $c ) = @_;

    # Fetch the data center info from fastly
    # XXX: will not work unless you have the credentials
    my $datacenters = $c->datacenters;

    $c->add_surrogate_key('datacenters');
    $c->cdn_cache_ttl( $c->cdn_times->{one_day} );
    $c->res->header(
        'Cache-Control' => 'max-age=' . $c->cdn_times->{one_day} );
    $c->stash( { success => $datacenters } );
    $c->detach( $c->view('JSON') );
}

__PACKAGE__->meta->make_immutable;

1;
