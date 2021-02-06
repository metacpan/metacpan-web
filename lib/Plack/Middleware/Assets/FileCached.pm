package Plack::Middleware::Assets::FileCached;
use File::Temp ();
use Digest::SHA qw( sha1_hex );
use File::Path ();
use Moo;

with 'Plack::Middleware::Assets::Core';

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

sub _build__static_app {
    my $self      = shift;
    my $cache_dir = $self->cache_dir;
    my $file_app  = Plack::App::File->new( root => "$cache_dir" )->to_app;
    sub {
        my $res = &$file_app;
        push @{ $res->[1] }, 'Cache-Control',
            'public, max-age=31536000, immutable';
        return $res;
    };
}

sub _build__asset_files {
    my $self      = shift;
    my @files     = @{ $self->files };
    my $extension = $self->extension;
    my $mount     = $self->mount;
    my $read_file = $self->read_file;
    my $content   = join "\n", map { $read_file->($_) } @files;
    if ( my $filter = $self->filter ) {
        $content = $filter->($content);
    }
    my $key       = sha1_hex($content);
    my $file      = "$key." . $extension;
    my $disk_file = $self->cache_dir . "/$file";
    if ( !-e $disk_file ) {
        open my $fh, '>', $disk_file
            or die "can't open $disk_file: $!";
        print {$fh} $content;
        close $fh;
    }
    ["/$mount/$file"];
}

1;
