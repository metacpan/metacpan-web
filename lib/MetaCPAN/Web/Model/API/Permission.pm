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

    if ( $type eq 'distribution' ) {
        return $self->_get_modules_in_distribution($name);
    }

    return $self->_get_author_modules($name);
}

sub _get_author_modules {
    my $self = shift;
    my $name = shift;

    my $search = {
        query => {
            bool => {
                should => [
                    { term => { owner          => $name } },
                    { term => { co_maintainers => $name } },
                ],
            },
        },
        size => 5_000,
    };

    return $self->_search_perms($search);
}

sub _get_modules_in_distribution {
    my $self = shift;
    my $name = shift;
    return undef unless $name;

    # ugh. Can't see a better way to get a model.
    my $model = MetaCPAN::Web::Model::API::Release->new(
        api_secure => $self->{api_secure} );

    my $res = $self->request("/package/modules/$name")->recv;
    my @modules = $res->{modules} ? @{ $res->{modules} } : undef;

    return undef unless @modules;

    my @perm_search
        = map { +{ term => { module_name => $_ } } } @modules;

    my $search = {
        query => { bool => { should => \@perm_search } },
        size  => 1_000,
    };

    return $self->_search_perms($search);
}

sub _search_perms {
    my $self   = shift;
    my $search = shift;

    my $perms_found = $self->request( '/permission/_search', $search )->recv;
    my @perms = sort { $a->{module_name} cmp $b->{module_name} }
        map { $_->{_source} } @{ $perms_found->{hits}->{hits} };
    return @perms ? \@perms : undef;
}

__PACKAGE__->meta->make_immutable;

1;
