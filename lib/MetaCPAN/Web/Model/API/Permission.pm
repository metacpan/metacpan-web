package MetaCPAN::Web::Model::API::Permission;

use Moose;

extends 'MetaCPAN::Web::Model::API';

use MetaCPAN::Web::Model::API::Release ();

=head1 NAME

MetaCPAN::Web::Model::Permission - Catalyst Model for 06perms

=cut

sub get {
    my ( $self, $type, $name ) = @_;
    return Future->done(undef) unless $name;

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
    my ( $self, $name ) = @_;

    $self->request("/permission/by_author/$name")->transform(
        done => sub {
            $_[0]->{permissions};
        }
    );
}

sub _get_modules_in_distribution {
    my ( $self, $name ) = @_;

    $self->request("/package/modules/$name")->then(
        sub {
            my $res = shift;
            return Future->done(undef)
                unless keys %{$res};

            $self->request( '/permission/by_module', undef,
                { module => $res->{modules} } )->transform(
                done => sub {
                    $_[0]->{permissions};
                }
                );
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
