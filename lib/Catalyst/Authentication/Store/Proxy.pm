package Catalyst::Authentication::Store::Proxy;
use Moose;
use Catalyst::Utils;

has user_class => (
    is       => 'ro',
    required => 1,
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_user_class'
);
has handles => ( is => 'ro', isa => 'HashRef' );
has config  => ( is => 'ro', isa => 'HashRef' );
has app     => ( is => 'ro', isa => 'ClassName' );
has realm   => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $config, $app, $realm ) = @_;
    my $handles = {
        map { $_ => $_ } qw(from_session for_session find_user),
        %{ $config->{handles} || {} },
        app   => $app,
        realm => $realm,
    };
    return {
        handles => $handles,
        app     => $app,
        realm   => $realm,
        $config->{user_class} ? ( user_class => $config->{user_class} ) : (),
        config => $config
    };
}

sub BUILD {
    my $self = shift;
    Catalyst::Utils::ensure_class_loaded( $self->user_class );
    return $self;
}

sub _build_user_class {
    shift->app . "::User";
}

sub new_object {
    my ($self, $c) = @_;
    return $self->user_class->new( $self->config, $c );
}

sub from_session {
    my ( $self, $c, $frozenuser ) = @_;
    my $user = $self->new_object( $self->config, $c );
    my $delegate = $self->handles->{from_session};
    return $user->$delegate( $c, $frozenuser );
}

sub for_session {
    my ( $self, $c, $user ) = @_;
    my $delegate = $self->handles->{for_session};
    return $user->$delegate($c);
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;
    my $user = $self->new_object( $self->config, $c );
    my $delegate = $self->handles->{find_user};
    return $user->$delegate( $authinfo, $c );

}

1;
