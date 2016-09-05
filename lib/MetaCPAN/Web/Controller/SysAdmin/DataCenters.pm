package MetaCPAN::Web::Controller::SysAdmin::DataCenters;

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
    $c->cdn_max_age( '1d' );
    $c->browser_max_age('1d');

    $c->stash( { success => $datacenters } );
    $c->detach( $c->view('JSON') );
}

__PACKAGE__->meta->make_immutable;

1;
