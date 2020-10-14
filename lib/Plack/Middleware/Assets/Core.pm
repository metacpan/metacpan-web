package Plack::Middleware::Assets::Core;
use Moo::Role;
use Plack::App::File;

sub wrap {
    my ( $self, $app, @args ) = @_;
    if ( ref $self ) {
        $self = $self->clone( app => $app );
    }
    else {
        $self = $self->new( { app => $app, @args } );
    }
    $self->to_app;
}

sub clone {
    my $self = shift;
    ( ref $self )->new( %$self, @_ );
}

has app => ( is => 'ro', required => 1 );
has wrapped => ( is => 'lazy', init_arg => 0, reader => 'to_app' );

has files     => ( is => 'ro', required => 1 );
has read_file => (
    is      => 'ro',
    default => sub {
        sub {
            my ($file) = @_;
            open my $fh, '<', $file
                or die "can't open $file: $!";
            my $content = do { local $/; <$fh> };
            close $fh;
            $content;
        };
    }
);
has filter => ( is => 'ro' );
has mount  => ( is => 'ro', default => '_assets' );

has extension => (
    is      => 'lazy',
    default => sub {
        my %uniq;
        my @ext = grep { !$uniq{$_}++ }
            map { /([^.]+)$/; $1 } @{ $_[0]->files };

        if ( @ext > 1 ) {
            die "extension must be specified if not all matching: @ext";
        }
        $ext[0];
    },
);

has _asset_files => ( is => 'lazy' );
has _static_app  => ( is => 'lazy' );

sub _build_wrapped {
    my $self = shift;

    my $mount = $self->mount;

    my $app      = \&{ $self->app };
    my $mount_re = qr{^(/\Q$mount\E)(/.*)};

    my @asset_files = @{ $self->_asset_files };

    my $static_app = $self->_static_app;

    sub {
        my ($env) = @_;

        if ( $env->{PATH_INFO} =~ $mount_re ) {
            local $env->{SCRIPT_NAME} = $env->{SCRIPT_NAME} . $1;
            local $env->{PATH_INFO}   = $2;
            my $res = $static_app->($env);
            return $res
                unless $res->[0] == 404;
        }

        push @{ $env->{'psgix.assets'} ||= [] }, @asset_files;
        $app->(@_);
    };
}

1;
