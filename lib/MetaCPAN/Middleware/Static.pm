package MetaCPAN::Middleware::Static;
use strict;
use warnings;
use Cpanel::JSON::XS ();
use Cwd              qw( cwd );
use Plack::App::File ();
use Plack::Builder   qw( builder enable mount );
use Plack::MIME      ();
use Plack::Util      ();

Plack::MIME->add_type(
    '.eot'   => 'application/vnd.ms-fontobject',
    '.map'   => 'application/json',
    '.mjs'   => 'application/javascript',
    '.otf'   => 'font/otf',
    '.woff2' => 'application/font-woff2',
);

sub new { bless {}, $_[0] }

my $hour_ttl = 60 * 60;
my $day_ttl  = $hour_ttl * 24;
my $year_ttl = $day_ttl * 365;

sub _response_mw {
    my ( $app, $cb ) = @_;
    sub { Plack::Util::response_cb( $app->(@_), $cb ) };
}

sub _add_headers {
    my ( $app, $add_headers ) = @_;
    _response_mw(
        $app,
        sub {
            my $res = shift;
            my ( $status, $headers ) = @$res;
            if ( $status >= 200 && $status < 300 ) {
                push @$headers, @$add_headers;
            }
            return $res;
        }
    );
}

sub _add_surrogate_keys {
    my ($app) = @_;
    _response_mw(
        $app,
        sub {
            my $res     = shift;
            my $headers = $res->[1];
            if ( my $content_type
                = Plack::Util::header_get( $headers, 'Content-Type' ) )
            {
                $content_type =~ s/;.*//;
                my $media_type = $content_type =~ s{/.*}{}r;
                push @$headers,
                    'Surrogate-Key' => join( ', ',
                    map "content_type=$_",
                    $content_type, $media_type );
            }
            return $res;
        }
    );
}

sub _file_app {
    my ( $type, $path, $headers ) = @_;
    _add_surrogate_keys( _add_headers(
        Plack::App::File->new( $type => $path )->to_app, $headers,
    ) );
}

sub _get_assets {
    my ($root) = @_;
    open my $fh, '<', "$root/assets/assets.json"
        or die "can't find asset map";
    my $json = do { local $/; <$fh> };
    close $fh;
    my $files = Cpanel::JSON::XS->new->decode($json);
    return [ map "/assets/$_", @$files ];
}

sub wrap {
    my ( $self, $app, %args ) = @_;
    my $root_dir = $args{root} || cwd;
    my $root     = "$root_dir/root";
    my $dev_mode
        = exists $args{dev_mode}
        ? $args{dev_mode}
        : ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' );

    my $assets;
    if ( !$dev_mode ) {
        $assets = _get_assets($root);
    }

    builder {
        enable sub {
            my ($app) = @_;
            sub {
                my ($env) = @_;
                if ($dev_mode) {
                    $assets = _get_assets($root);
                }
                push @{ $env->{'metacpan.assets'} ||= [] }, @$assets;
                $app->($env);
            };
        };

        mount '/favicon.ico' => _file_app(
            file => "$root/static/icons/favicon.ico",
            [
                'Cache-Control'     => "public, max-age=${day_ttl}",
                'Surrogate-Control' => "max-age=${year_ttl}",
                'Surrogate-Key'     => 'assets',
            ],
        );

        for my $static_dir ( qw(
            assets
            static/icons
            static/images
        ) )
        {
            mount "/$static_dir" => _file_app(
                root => "$root/$static_dir",
                [
                    'Cache-Control' =>
                        "public, max-age=${year_ttl}, immutable",
                    'Surrogate-Control' => "max-age=${year_ttl}",
                    'Surrogate-Key'     => 'assets',
                ],
            );
        }

        mount "/static" => _file_app(
            root => "$root/static",
            [
                $dev_mode
                ? ( 'Cache-Control' => "public, max-age=${day_ttl}", )
                : ( 'Cache-Control' => "public", ),
                'Surrogate-Control' => "max-age=${year_ttl}",
                'Surrogate-Key'     => 'assets',
            ],
        );

        mount '/' => $app;
    };
}

1;
