package Plack::Middleware::Assets::FileCached;
use Moo;
use File::Temp ();
use Plack::App::File;
use Digest::SHA qw(sha1_hex);
use File::Path ();

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

has files => ( is => 'ro', required => 1 );
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
has mount => ( is => 'ro', default => '_assets' );

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
    }
);

has cache_dir => (
    is      => 'ro',
    default => sub {
        File::Temp->newdir( 'plack_assets_XXXXX', TMPDIR => 1 );
    },
    coerce => sub {
        my $dir = shift;
        if ( !-e $dir ) {
            File::Path::mkpath($dir);
        }
        $dir;
    },
);

has _asset_files => ( is => 'lazy' );

sub _build_wrapped {
    my $self = shift;

    my $cache_dir = $self->cache_dir;
    my $mount     = $self->mount;

    my $file_app = Plack::App::File->new( root => "$cache_dir" )->to_app;
    my $static_app = sub {
        my $res = &$file_app;
        push @{ $res->[1] }, 'Cache-Control', 'max-age=31556926';
        return $res;
    };

    my $app      = \&{ $self->app };
    my $mount_re = qr{^(/\Q$mount\E)(/.*)};

    my @asset_files = @{ $self->_asset_files };

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

sub _build__asset_files {
    my $self      = shift;
    my $read_file = $self->read_file;
    my @files     = @{ $self->files };
    my @assets;
    my $content = join "\n", map { $read_file->($_) } @files;
    if ( my $filter = $self->filter ) {
        $content = $filter->($content);
    }
    my $key       = sha1_hex($content);
    my $file      = "$key." . $self->extension;
    my $disk_file = $self->cache_dir . "/$file";
    if ( !-e $disk_file ) {
        open my $fh, '>', $disk_file
            or die "can't open $disk_file: $!";
        print {$fh} $content;
        close $fh;
    }
    push @assets, '/' . $self->mount . "/$file";
    \@assets;
}

1;
