package MetaCPAN::Middleware::Static;
use strict;
use warnings;
use Plack::Builder   qw( builder enable mount );
use Plack::App::File ();
use Cwd              qw( cwd );
use Plack::MIME      ();
use Cpanel::JSON::XS ();

Plack::MIME->add_type(
    '.eot'   => 'application/vnd.ms-fontobject',
    '.otf'   => 'font/otf',
    '.ttf'   => 'font/ttf',
    '.woff'  => 'application/font-woff',
    '.woff2' => 'application/font-woff2',
);

sub new { bless {}, $_[0] }

my $hour_ttl = 60 * 60;
my $day_ttl  = $hour_ttl * 24;
my $year_ttl = $day_ttl * 365;

sub wrap {
    my ( $self, $app, %args ) = @_;
    my $root_dir = $args{root} || cwd;
    my $dev_mode
        = exists $args{dev_mode}
        ? $args{dev_mode}
        : ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' );

    my $get_assets = sub {
        open my $fh, '<', "$root_dir/root/assets/assets.json"
            or die "can't find asset map";
        my $json = do { local $/; <$fh> };
        close $fh;
        my $files = Cpanel::JSON::XS->new->decode($json);
        return [ map "/assets/$_", @$files ];
    };

    my $assets;
    if ( !$dev_mode ) {
        $assets = $get_assets->();
    }

    builder {
        enable sub {
            my ($app) = @_;
            sub {
                my ($env) = @_;
                if ($dev_mode) {
                    $assets = $get_assets->();
                }
                push @{ $env->{'psgix.assets'} ||= [] }, @$assets;
                $app->($env);
            };
        };

        mount '/sitemap-authors.xml.gz' => Plack::App::File->new(
            file => 'root/static/sitemaps/sitemap-authors.xml.gz' )->to_app;
        mount '/sitemap-releases.xml.gz' => Plack::App::File->new(
            file => 'root/static/sitemaps/sitemap-releases.xml.gz' )->to_app;

        my $favicon_app
            = Plack::App::File->new( file => 'root/static/icons/favicon.ico' )
            ->to_app;
        mount '/favicon.ico' => sub {
            my $res = $favicon_app->(@_);
            push @{ $res->[1] },
                (
                'Cache-Control'     => "max-age=${day_ttl}",
                'Surrogate-Control' => "max-age=${year_ttl}",
                'Surrogate-Key'     => 'assets',
                );
            $res;
        };
        my $static_app
            = Plack::App::File->new( root => 'root/static' )->to_app;
        mount '/static' => sub {
            my $env = shift;
            my $res = $static_app->($env);
            if ( $env->{PATH_INFO} =~ m{^/(?:images|icons|fonts|modules)/} ) {
                push @{ $res->[1] },
                    ( 'Cache-Control' =>
                        "public, max-age=${year_ttl}, immutable", );
            }
            else {
                push @{ $res->[1] },
                    ( 'Cache-Control' => "public, max-age=${day_ttl}", );
            }
            push @{ $res->[1] },
                (
                'Surrogate-Key'     => 'assets',
                'Surrogate-Control' => "max-age=${year_ttl}",
                );
            $res;
        };
        my $assets_app
            = Plack::App::File->new( root => 'root/assets' )->to_app;
        mount '/assets' => sub {
            my $env = shift;
            my $res = $assets_app->($env);
            push @{ $res->[1] },
                (
                'Cache-Control' => "public, max-age=${year_ttl}, immutable",
                'Surrogate-Key' => 'assets',
                'Surrogate-Control' => "max-age=${year_ttl}",
                );
            return $res;
        };

        mount '/' => $app;
    };
}

1;
