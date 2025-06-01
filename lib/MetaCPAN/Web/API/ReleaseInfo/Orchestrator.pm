package MetaCPAN::Web::API::ReleaseInfo::Orchestrator;
use Moo;
use List::Util qw( max );
use namespace::clean;

has model => (
    is       => 'ro',
    required => 1,
);

has dist => ( is => 'ro' );

has author  => ( is => 'ro' );
has release => ( is => 'ro' );

sub BUILD {
    my $self = shift;
    die "dist or author and release must be provided"
        if $self->dist
        ? ( $self->author || $self->release )
        : !( $self->author && $self->release );
}

has [qw(_with_release _with_dist _with_release_detail _then)] => (
    is      => 'ro',
    default => sub { [] },
);

sub with_release {
    my ( $self, @cb ) = @_;
    $self->new( %$self, _with_release => [ @{ $self->_with_release }, @cb ] );
}

sub with_dist {
    my ( $self, @cb ) = @_;
    $self->new( %$self, _with_dist => [ @{ $self->_with_dist }, @cb ] );
}

sub with_release_detail {
    my ( $self, @cb ) = @_;
    $self->new( %$self,
        _with_release_detail => [ @{ $self->_with_release_detail }, @cb ] );
}

sub then {
    my ( $self, $then ) = @_;
    $self->new( %$self, _then => [ @{ $self->_then }, $then ] );
}

sub _to_future {
    my @in = @_;
    Future->wait_all(
        map {
            my ( $to, $future, $from ) = @$_;
            $from ||= $to;
            $future->then( sub {
                my $data = shift;
                if ( my $sub = $data->{$from} ) {
                    return Future->done( {
                        $to => $sub,
                        (
                            exists $data->{took}
                            ? ( took => $data->{took} )
                            : ()
                        ),
                    } );
                }
                else {
                    return Future->fail($data);
                }
            } );
        } @in
    );
}

sub _unwrap {
    Future->done( map $_->result, @_ );
}

# this should be directly in the release model methods
sub _fail_without_release {
    my $data = shift;
    return Future->fail( { code => 404, message => 'Not found' } )
        unless $data->{release};
    Future->done($data);
}

sub _via_dist {
    my ( $self, $dist ) = @_;
    my $model = $self->model;

    Future->wait_all(
        $model->find($dist)->then( \&_fail_without_release )->then( sub {
            my $data         = shift;
            my $release_data = $data->{release};
            my $author       = $release_data->{author};
            my $release      = $release_data->{name};

            _to_future(
                ( map $_->( $author, $release ), @{ $self->_with_release } ),
                ( map $_->($release_data), @{ $self->_with_release_detail } ),
                [ release => Future->done($data) ],
            );
        } ),
        _to_future(
            ( map $_->($dist), @{ $self->_with_dist } ),
        ),
    )->then( \&_unwrap );
}

sub _via_release {
    my ( $self, $author, $release ) = @_;
    my $model = $self->model;

    Future->wait_all(
        $model->get( $author, $release )
            ->then( \&_fail_without_release )
            ->then( sub {
            my $data         = shift;
            my $release_data = $data->{release};
            my $dist         = $release_data->{distribution};

            _to_future(
                ( map $_->($dist), @{ $self->_with_dist } ),
                ( map $_->($release_data), @{ $self->_with_release_detail } ),
                [ release => Future->done($data) ],
            );
            } ),
        _to_future(
            ( map $_->( $author, $release ), @{ $self->_with_release } ),
        ),
    )->then( \&_unwrap );
}

sub fetch {
    my $self = shift;
    my $result
        = $self->dist
        ? $self->_via_dist( $self->dist )
        : $self->_via_release( $self->author, $self->release );

    $result = $result->then( sub {
        my @res = map $_->else_done( {} )->get, @_;

        Future->done( {
            ( map %$_, @res ),
            took => max( grep defined, map $_->{took}, values @res ),
        } );
    } );
    for my $then ( @{ $self->_then } ) {
        $result = $result->then($then);
    }
    return $result;
}

1;
