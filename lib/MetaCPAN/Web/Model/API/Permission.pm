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
        return $self->request( '/permission/' . $name )->transform(
            done => sub {

                # return undef if there's a 404
                my $data = shift;
                return $data->{code} ? undef : $data;
            }
        );
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
    return Future->done(undef) unless $name;

    $self->request("/package/modules/$name")->then(
        sub {
            my $res = shift;
            my @modules = $res->{modules} ? @{ $res->{modules} } : undef;

            return Future->done(undef) unless @modules;

            my @perm_search
                = map { +{ term => { module_name => $_ } } } @modules;

            my $search = {
                query => { bool => { should => \@perm_search } },
                size  => 1_000,
            };

            return $self->_search_perms($search);
        }
    );
}

sub _search_perms {
    my $self   = shift;
    my $search = shift;

    $self->request( '/permission/_search', $search )->transform(
        done => sub {
            my $perms = shift;
            my @perms = sort { $a->{module_name} cmp $b->{module_name} }
                map { $_->{_source} } @{ $perms->{hits}->{hits} };
            return @perms ? \@perms : undef;
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
