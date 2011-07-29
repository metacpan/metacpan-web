package MetaCPAN::Web::API;

use Moose;
use Class::MOP;
use namespace::autoclean;
with 'MetaCPAN::Web::API::Request';

has author => (
    builder => '_build_author',
    is      => 'ro',
    isa     => 'MetaCPAN::Web::API::Author',
);

has favorite => (
    builder => '_build_favorite',
    is      => 'ro',
    isa     => 'MetaCPAN::Web::API::Favorite',
);

has module => (
    builder => '_build_module',
    is      => 'ro',
    isa     => 'MetaCPAN::Web::API::Module',
);

has rating => (
    builder => '_build_rating',
    is      => 'ro',
    isa     => 'MetaCPAN::Web::API::Rating',
);

has release => (
    builder => '_build_release',
    is      => 'ro',
    isa     => 'MetaCPAN::Web::API::Release',
);

has user => (
    builder => '_build_user',
    is      => 'ro',
    isa     => 'MetaCPAN::Web::API::User',
);

sub _build_author {
    shift->_build_instance_of('MetaCPAN::Web::API::Author');
}

sub _build_favorite {
    shift->_build_instance_of('MetaCPAN::Web::API::Favorite');
}

sub _build_instance_of {
    my ( $self, $class ) = @_;
    Class::MOP::load_class($class);
    return $class->new(
        api        => $self->api,
        api_secure => $self->api_secure,
        ctx        => $self,
    );
}

sub _build_module {
    shift->_build_instance_of('MetaCPAN::Web::API::Module');
}

sub _build_rating {
    shift->_build_instance_of('MetaCPAN::Web::API::Rating');
}

sub _build_release {
    shift->_build_instance_of('MetaCPAN::Web::API::Release');
}

sub _build_user {
    shift->_build_instance_of('MetaCPAN::Web::API::User');
}

__PACKAGE__->meta->make_immutable;

1;
