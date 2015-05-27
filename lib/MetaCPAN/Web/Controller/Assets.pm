package MetaCPAN::Web::Controller::Assets;
use Moose;
use namespace::autoclean;

use Capture::Tiny ':all';
use CSS::Minifier::XS qw();
use JavaScript::Minifier::XS qw();
use String::BOM qw(string_has_bom strip_bom_from_string);

BEGIN { extends 'MetaCPAN::Web::Controller' }

=head1 NAME

MetaCPAN::Web::Controller::Assets - css / js assets

=head1 DESCRIPTION

Generate assets dynamically, rely on CDN to cache them
for the public and on DEV don't

=cut

=head2 style.css

Pass static/less/style.less through less

=cut

sub css : Path('style.css') : Args(0) {
    my ( $self, $c ) = @_;

    $c->res->content_type('text/css');

    my $file = 'root/static/less/style.less';

    my $less = `lessc -v`;
    croak(q{Can't find lessc command}) unless $less;

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'lessc', $file );
    };
    die $stderr if $stderr;

    # cdn cache
    $c->add_surrogate_key('assets');
    $c->add_surrogate_key('css');
    $c->cdn_cache_ttl( $c->one_month );    # 30 days

    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {

        # Make sure the user re-requests each time
        $c->res->header( 'Cache-Control' => 'max-age=0, no-store, no-cache' );
        $c->res->body($stdout);

    }
    else {

        # browser cache
        $c->res->header( 'Cache-Control' => 'max-age=' . $c->one_hour );
        $c->res->body( CSS::Minifier::XS::minify($stdout) );

    }
}

sub js : Path('mc.js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->res->content_type('application/javascript');

    my @js_files = map {"root/static/js/$_.js"} (
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

    my $out;
    local $/ = undef;
    foreach my $file (@js_files) {
        open my $fh, "<", $file
            or die "could not open $file: $!";
        my $content = <$fh>;
        close($fh);

        if ( string_has_bom($content) ) {
            $content = strip_bom_from_string($content);
        }
        $out .= "\n/* $file */\n";
        $out .= $content;
    }

    # cdn cache
    $c->add_surrogate_key('assets');
    $c->add_surrogate_key('js');
    $c->cdn_cache_ttl( $c->one_month );    # 30 days

    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {

        # Make sure the user re-requests each time
        $c->res->header( 'Cache-Control' => 'max-age=0, no-store, no-cache' );
        $c->res->body( JavaScript::Minifier::XS::minify($out) );

    }
    else {

        # browser cache
        $c->res->header( 'Cache-Control' => 'max-age=' . $c->one_hour );
        $c->res->body( JavaScript::Minifier::XS::minify($out) );

    }
}

1;
