package Plack::Middleware::Assets::Dev;
use Digest::SHA qw( sha1_hex );
use Moo;

with 'Plack::Middleware::Assets::Core';

has _file_map => ( is => 'lazy' );

sub _build__file_map {
    my $self  = shift;
    my @files = @{ $self->files };
    return { map +( sha1_hex($_) => $_ ), @files };
}

sub _build__static_app {
    my $self = shift;

    my $file_map  = $self->_file_map;
    my $read_file = $self->read_file;
    my $ext       = $self->extension;
    my $type
        = Plack::MIME->mime_type( '.' . $ext ) || 'application/octet-stream';
    my $filter = $self->filter;

    sub {
        my ($env) = @_;
        my $path = $env->{PATH_INFO};

        if (    $path
            and $path =~ m{^/(.*)\.\Q$ext\E$}
            and my $file = $file_map->{$1} )
        {
            my $content = $read_file->($file);
            $content = $filter->($content)
                if $filter;
            return [
                200,
                [
                    'Content-Type' => $type,
                    'Cache-Control', 'no-cache',
                ],
                [$content]
            ];
        }
        return [ 404, [], [] ];
    };
}

sub _build__asset_files {
    my $self      = shift;
    my $extension = $self->extension;
    my $mount     = $self->mount;
    my $file_map  = $self->_file_map;
    return [
        map "/$mount/$_.$extension",
        sort { $file_map->{$a} cmp $file_map->{$b} } keys %$file_map
    ];
}

1;
