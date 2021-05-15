package MetaCPAN::Web::Controller::SysAdmin::DataCenters;

use MetaCPAN::Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# This is used by https://mirrors.cpan.org/ fetch our
# datacenters and update the official CPAN list

# /sysadmin/datacenters/list
sub list_datacenters : Path('list') : Args(0) GET {
    my ( $self, $c ) = @_;
    $c->stash( { current_view => 'JSON' } );

    # Fetch the data center info from fastly
    # XXX: will not work unless you have the credentials
    my $datacenters;

    if ( my $net_fastly = $c->cdn_api() ) {

        # Uses the private interface as fastly client doesn't
        # have this end point yet
        $datacenters = $net_fastly->client->_get('/datacenters');

    }

    $c->add_surrogate_key('datacenters');
    $c->cdn_max_age('1d');
    $c->browser_max_age('1d');

    $c->stash( { json => { success => $datacenters } } );
}

__PACKAGE__->meta->make_immutable;

1;
