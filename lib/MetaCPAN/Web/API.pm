package MetaCPAN::Web::API;

use Moose;
use Class::MOP;
use namespace::autoclean;
with 'MetaCPAN::Web::API::Request';

has author => (
    builder    => '_build_author',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::Author',
    lazy_build => 1,
);

has favorite => (
    builder    => '_build_favorite',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::Favorite',
    lazy_build => 1,
);

has mirror => (
    builder    => '_build_mirror',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::Mirror',
    lazy_build => 1,
);

has module => (
    builder    => '_build_module',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::Module',
    lazy_build => 1,
);

has rating => (
    builder    => '_build_rating',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::Rating',
    lazy_build => 1,
);

has release => (
    builder    => '_build_release',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::Release',
    lazy_build => 1,
);

has user => (
    builder    => '_build_user',
    is         => 'ro',
    isa        => 'MetaCPAN::Web::API::User',
    lazy_build => 1,
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
        url        => $self->url,
        url_secure => $self->url_secure,
        api        => $self,
    );
}

sub _build_mirror {
    shift->_build_instance_of('MetaCPAN::Web::API::Mirror');
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
