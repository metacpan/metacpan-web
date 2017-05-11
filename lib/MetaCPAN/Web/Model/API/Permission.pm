package MetaCPAN::Web::Model::API::Permission;

use Moose;

extends 'MetaCPAN::Web::Model::API';

use MetaCPAN::Web::Model::API::Release ();

=head1 NAME

MetaCPAN::Web::Model::Permission - Catalyst Model for 06perms

=cut

sub get {
    my ( $self, $type, $name ) = @_;

    if ( $type eq 'module' ) {
        my $module = $self->request( '/permission/' . $name )->recv;

        # return undef if there's a 404
        return $module->{code} ? undef : $module;
    }

    my $release = $self->request( '/release/' . $name )->recv;

    # ugh
    my $model = MetaCPAN::Web::Model::API::Release->new(
        api_secure => $self->{api_secure} );

    my $pkg_search = {
        query => {
            bool => {
                must => [
                    { term => { distribution => $release->{distribution} } },
                    { term => { dist_version => $release->{version} } },
                ]
            },
        },
        size => 1_000,
    };

    my $found_modules
        = $self->request( '/package/_search', $pkg_search )->recv;

    my @modules = map { $_->{_source}->{module_name} }
        @{ $found_modules->{hits}->{hits} };

    return undef unless @modules;

    my @perm_search
        = map { +{ term => { module_name => $_ } } } @modules;

    my $search = {
        query => { bool => { should => \@perm_search } },
        size  => 1_000,
    };

    my $perms_found = $self->request( '/permission/_search', $search )->recv;
    my @perms = sort { $a->{module_name} cmp $b->{module_name} }
        map { $_->{_source} } @{ $perms_found->{hits}->{hits} };
    return \@perms;
}

__PACKAGE__->meta->make_immutable;

1;
