package MetaCPAN::Web::Authentication::Store;
use MetaCPAN::Web::Types qw(LoadableClass);
use Moo;

has user_class => (
    is      => 'ro',
    isa     => LoadableClass,
    default => 'MetaCPAN::Web::Authentication::User',
    handles => [ qw(
        from_session
        find_user
    ) ],
);
has realm => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $config, $c, $realm ) = @_;
    return { %$config, realm => $realm, };
}

sub for_session {
    my ( $self, $c, $user ) = @_;
    $user->for_session;
}

sub user_supports { }

1;
