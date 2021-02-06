package MetaCPAN::Middleware::Static;
use strict;
use warnings;
use Plack::Builder qw( builder enable mount );
use Plack::App::File;
use JavaScript::Minifier::XS ();
use Cwd qw( cwd );
use Plack::MIME;

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
    my $tempdir = $args{temp_dir};
    my $config  = $args{config};
    my $lessc   = $config->{lessc_command};
    if ( $lessc && `$lessc --version` !~ /lessc/ ) {
        undef $lessc;
    }

    my @js_files = map {"/static/$_"} (
        qw(
            js/jquery.min.js
            js/jquery.tablesorter.js
            js/jquery.relatize_date.js
            js/jquery.qtip.min.js
            js/jquery.autocomplete.min.js
            js/mousetrap.min.js
            js/shCore.js
            js/shBrushPerl.js
            js/shBrushPlain.js
            js/shBrushYaml.js
            js/shBrushJScript.js
            js/shBrushDiff.js
            js/shBrushCpp.js
            js/shBrushCPANChanges.js
            js/cpan.js
            js/toolbar.js
            js/github.js
            js/dropdown.js
            modules/bootstrap-v3.4.1/js/dropdown.js
            modules/bootstrap-v3.4.1/js/collapse.js
            modules/bootstrap-v3.4.1/js/modal.js
            modules/bootstrap-v3.4.1/js/tooltip.js
            modules/bootstrap-v3.4.1/js/affix.js
            js/bootstrap-slidepanel.js
            js/syntaxhighlighter.js
        ),
    );

    my @css_files = map { my $f = $_; $f =~ s{^\Q$root_dir\E/root/}{/}; $f }
        glob "$root_dir/root/static/css/*.css";

    my @less_files = ('/static/less/style.less');

    builder {
        if ( !$dev_mode ) {
            die "no lessc available!"
                if !defined $lessc;

            enable 'Assets::FileCached' => (
                files => [ map "root$_", @js_files ],

                filter => sub { JavaScript::Minifier::XS::minify( $_[0] ) },
                ( $tempdir ? ( cache_dir => "$tempdir/assets" ) : () ),
            );

            enable 'Assets::FileCached' => (
                files     => [ map "root$_", @css_files, @less_files ],
                extension => 'css',
                read_file => sub { scalar `$lessc -s $_[0]` },
                ( $tempdir ? ( cache_dir => "$tempdir/assets" ) : () ),
            );
        }
        else {
            my @assets = (@js_files);
            if ($lessc) {
                enable 'Assets::Dev' => (
                    files     => [ map "root$_", @css_files, @less_files ],
                    extension => 'css',
                    read_file => sub {
                        my $file = shift;
                        my ($root_path) = $file =~ m{^root/(.*)/};
                        return
                            scalar
                            `$lessc -s --source-map-map-inline --source-map-rootpath="/$root_path/" "$file"`;
                    },
                );
            }
            else {
                push @assets, '/static/js/less.min.js', @css_files,
                    @less_files;
            }

            enable sub {
                my ($app) = @_;
                sub {
                    my ($env) = @_;
                    push @{ $env->{'psgix.assets'} ||= [] }, @assets;
                    $app->($env);
                };
            };
        }

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

        mount '/' => $app;
    };
}

1;
