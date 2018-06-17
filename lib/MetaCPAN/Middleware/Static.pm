package MetaCPAN::Middleware::Static;
use strict;
use warnings;
use Plack::Builder;
use Plack::App::File;
use JavaScript::Minifier::XS ();
use Cwd qw(cwd);

sub new { bless {}, $_[0] }

my $hour_ttl = 60 * 60;
my $day_ttl  = $hour_ttl * 24;
my $year_ttl = $day_ttl * 365;

sub wrap {
    my ( $self, $app, %args ) = @_;
    my $root_dir = $args{root} || cwd;
    my $dev_mode = $args{dev_mode}
        || ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' );
    my $tempdir = $args{temp_dir};

    my @js_files = map {"/static/js/$_.js"} (
        qw(
            jquery.min
            jquery.tablesorter
            jquery.relatize_date
            jquery.qtip.min
            jquery.autocomplete.min
            mousetrap.min
            shCore
            shBrushPerl
            shBrushPlain
            shBrushYaml
            shBrushJScript
            shBrushDiff
            shBrushCpp
            shBrushCPANChanges
            cpan
            toolbar
            github
            dropdown
            bootstrap/bootstrap-dropdown
            bootstrap/bootstrap-collapse
            bootstrap/bootstrap-modal
            bootstrap/bootstrap-tooltip
            bootstrap/bootstrap-affix
            bootstrap-slidepanel
            syntaxhighlighter
            ),
    );

    my @css_files = map { my $f = $_; $f =~ s{^\Q$root_dir\E/root/}{/}; $f }
        glob "$root_dir/root/static/css/*.css";

    my @less_files = ('/static/less/style.less');

    builder {
        if ( !$dev_mode ) {
            enable 'Assets::FileCached' => (
                files => [ map "root$_", @js_files ],

                filter => sub { JavaScript::Minifier::XS::minify( $_[0] ) },
                ( $tempdir ? ( cache_dir => "$tempdir/assets" ) : () ),
            );

            enable 'Assets::FileCached' => (
                files     => [ map "root$_", @css_files, @less_files ],
                extension => 'css',
                read_file => sub { scalar `lessc -s $_[0]` },
                ( $tempdir ? ( cache_dir => "$tempdir/assets" ) : () ),
            );
        }
        else {
            my @assets = (@js_files);
            if ( `lessc --version` =~ /lessc/ ) {
                enable 'Assets::Dev' => (
                    files     => [ map "root$_", @css_files, @less_files ],
                    extension => 'css',
                    read_file => sub {
                        my $file = shift;
                        my ($root_path) = $file =~ m{^root/(.*)/};
                        scalar
                            `lessc -s --source-map-map-inline --source-map-rootpath="/$root_path/" "$file"`;
                    },
                );
            }
            else {
                push @assets, @css_files, @less_files;
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
            my $res = $static_app->(@_);
            push @{ $res->[1] }, (
                'Cache-Control' => "max-age=${day_ttl}",

                'Surrogate-Control' => "max-age=${year_ttl}",
                'Surrogate-Key'     => 'assets',
            );
            $res;
        };

        mount '/' => $app;
    };
}

1;
