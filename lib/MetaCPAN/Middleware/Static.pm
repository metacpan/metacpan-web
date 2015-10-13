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
            contributors
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
            enable sub {
                my ($app) = @_;
                sub {
                    my ($env) = @_;
                    push @{ $env->{'psgix.assets'} ||= [] },
                        ( @js_files, @css_files, @less_files, );
                    $app->($env);
                };
            };
        }

        mount '/favicon.ico' =>
            Plack::App::File->new( file => 'root/static/icons/favicon.ico' )
            ->to_app;
        my $static_app
            = Plack::App::File->new( root => 'root/static' )->to_app;
        mount '/static' => sub {
            my $res = $static_app->(@_);
            push @{ $res->[1] }, (
                'Cache-Control' => "max-age=${hour_ttl}",

                'Surrogate-Control' => "max-age=${hour_ttl}",
                'Surrogate-Key'     => 'assets',
            );
            $res;
        };

        mount '/' => $app;
    };
}

1;
