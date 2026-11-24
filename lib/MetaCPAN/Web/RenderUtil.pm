package MetaCPAN::Web::RenderUtil;

use strict;
use warnings;

use Exporter qw(import);

use Carp           qw( croak );
use Digest::MD5    ();
use FFI::Platypus  ();
use HTML::Escape   qw( escape_html );
use HTML::Restrict ();
use Ref::Util      qw( is_plain_arrayref );
use URI            ();

# COMRAK_FFI_LIB overrides the library path, e.g. for local development
my $comrak_lib = $ENV{COMRAK_FFI_LIB} || '/usr/local/lib/libcomrak_ffi.so';
croak "libcomrak_ffi not found at $comrak_lib (set COMRAK_FFI_LIB)"
    unless -e $comrak_lib;
my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib($comrak_lib);
my $comrak_render = $ffi->function(
    'comrak_markdown_to_html' => [ 'string', 'int' ] => 'opaque' );
my $comrak_free
    = $ffi->function( 'comrak_free_string' => ['opaque'] => 'void' );

our @EXPORT_OK = qw(
    filter_html
    gravatar_image
    render_markdown
    split_index
);

sub filter_html {
    my ( $html, $data ) = @_;

    my $hr = HTML::Restrict->new(
        uri_schemes => [ undef, 'http', 'https', 'mailto', 'irc', 'ircs' ],
        rules       => {
            a       => [qw( href id target )],
            b       => [],
            br      => [],
            caption => [],
            center  => [],
            code    => [ { class => qr/^language-\S+$/ } ],
            dd      => [],
            div     => [ { class => qr/^pod-errors(?:-detail)?$/ } ],
            dl      => [],
            dt      => ['id'],
            em      => [],
            h1      => ['id'],
            h2      => ['id'],
            h3      => ['id'],
            h4      => ['id'],
            h5      => ['id'],
            h6      => ['id'],
            i       => [],
            li      => ['id'],
            ol      => [],
            nav     => [],
            p       => [],
            pre     => [ {
                class        => qr/^line-numbers$/,
                'data-line'  => qr/^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$/,
                'data-start' => qr/^\d+$/,
            } ],
            span   => [ { style => qr/^white-space: nowrap;$/ } ],
            strong => [],
            sub    => [],
            sup    => [],
            table  => [ qw( border cellspacing cellpadding align ), ],
            thead  => [],
            tbody  => [],
            tfoot  => [],
            th     => [qw( colspan rowspan )],
            td     => [qw( colspan rowspan )],
            tr     => [],
            u      => [],
            ul     => [],

            #
            # SVG tags.
            #
            circle   => [qw(id cx cy r style transform)],
            clippath => [qw(id clippathunits style transform)],
            defs     => [qw(id style transform)],
            ellipse  => [qw(id cx cy rx ry style transform)],
            g        => [qw(id style transform)],
            line     => [qw(id style transform x1 y1 x2 y2)],
            marker   => [
                qw(id markerheight markerunits markerwidth orient refx refy)],
            mask =>
                [qw(id height maskunits maskcontentunits style x y width)],
            lineargradient => [
                qw(id gradientunits gradienttransform spreadmethod
                    x1 x2 y1 y2 xlink:href)
            ],
            path           => [qw(id d pathlength style transform)],
            polygon        => [qw(id points style transform)],
            polyline       => [qw(id points style transform)],
            radialgradient => [
                qw(id gradientunits gradienttransform spreadmethod
                    cx cy fx fy r xlink:href)
            ],
            rect => [qw(id height style transform x y width)],
            stop => [qw(id offset style)],
            svg  => [ qw(id height preserveaspectratio version viewbox
                width xmlns xmlns:xlink) ],
            title => [qw(id style)],
            use   => [qw(id height transform width x xlink xlink:href y)],
        },
        replace_img => sub {

            # last arg is $text, which we don't need
            my ( $tagname, $attrs, undef ) = @_;
            my $tag = '<img';
            for my $attr (qw( alt border height width src title)) {
                next
                    unless exists $attrs->{$attr};
                my $val = $attrs->{$attr};
                if ( $attr eq 'src' ) {
                    if ( $val =~ m{^(?:(?:https?|ftp):)?//|^data:} ) {

                        # use directly
                    }
                    elsif ( $val =~ /^[0-9a-zA-Z.+-]+:/ ) {

                        # bad protocol
                        return q{};
                    }
                    elsif ($data) {
                        my $base = 'https://st.aticpan.org/source/';
                        if ( $val =~ s{^/}{} ) {
                            $base .= "$data->{author}/$data->{release}/";
                        }
                        else {
                            $base .= $data->{associated_pod}
                                || "$data->{author}/$data->{release}/$data->{path}";
                        }
                        $val = URI->new_abs( $val, $base )->as_string;
                    }
                    else {
                        $val = '/static/images/gray.png';
                    }
                }
                $tag .= qq{ $attr="} . escape_html($val) . qq{"};
            }
            $tag .= ' />';
            return $tag;
        },
    );
    $hr->process($html);
}

sub gravatar_image {
    my ( $author, $size ) = @_;
    my $email = q{};
    if ( $author && $author->{pauseid} ) {
        $email = $author->{pauseid} . '@cpan.org';
    }
    elsif ( $author && $author->{email} ) {
        $email
            = is_plain_arrayref( $author->{email} )
            ? ( $author->{email}[0] // q{} )
            : ( $author->{email} // q{} );
    }
    my $grav_id = Digest::MD5::md5_hex( lc $email );
    return sprintf 'https://www.gravatar.com/avatar/%s?d=identicon&s=%s',
        $grav_id, $size // 80;
}

sub split_index {
    my ($html) = @_;

    # this will hopefully be done by the API in the future
    $html =~ s{\A<ul id="index">(.*?^</ul>\n?)}{<nav><ul>$1</nav>}ms;

    # both of these regexes are kind of ugly, but we know the content produced
    # by the API, so it should still work fine.
    $html =~ s{\A<nav>(.*?)</nav>\n*}{}s;
    my $pod_index = $1;
    return ( $pod_index, $html );
}

sub render_markdown {
    my ( $markdown, %opts ) = @_;

    my $unsafe = delete $opts{unsafe} // 1;

    if (%opts) {
        croak "Unsupported options: " . join( ', ', sort keys %opts );
    }

    # comrak renders GFM markdown to HTML with extensions enabled
    # (tables, strikethrough, autolinks, header IDs). The unsafe flag
    # controls whether raw HTML in the markdown is passed through (1) or
    # stripped (0). Passed-through HTML is not sanitized here (comrak has
    # no tagfilter since 0.56), so untrusted input must go through
    # filter_html afterwards.
    #
    # comrak takes and returns UTF-8 bytes; Perl callers pass and expect
    # character strings. NUL would end the C string early, so replace it
    # as CommonMark does.
    my $bytes = $markdown // q{};
    $bytes =~ tr/\0/\x{FFFD}/;
    utf8::encode($bytes);
    my $ptr = $comrak_render->call( $bytes, $unsafe ? 1 : 0 )
        or croak 'comrak_markdown_to_html returned NULL';
    my $html = $ffi->cast( 'opaque', 'string', $ptr );
    $comrak_free->call($ptr);
    utf8::decode($html)
        or croak 'comrak_markdown_to_html returned invalid UTF-8';

    return _normalize_heading_anchors($html);
}

# comrak's header IDs extension emits an empty <a class="anchor"> in each
# heading. Leave the id on the heading and drop the <a>, so filter_html
# never has to allow class, aria-hidden or aria-label on links, which user
# content could abuse. createAnchors in document-ui.mjs adds the bookmark
# link client-side, as it does for POD. Handles both comrak formats:
#   < 0.54: <h1><a href="#x" aria-hidden="true" class="anchor" id="x"></a>X</h1>
#   >= 0.54: <h1 id="x">X<a href="#x" aria-label="..." ... class="anchor"></a></h1>
sub _normalize_heading_anchors {
    my ($html) = @_;

    $html =~ s{
        <(h[1-6])>
        <a\ href="\#([^"]*)"\ aria-hidden="true"\ class="anchor"\ id="\2"></a>
    }{<$1 id="$2">}gx;

    # Match the anchor itself, never scanning past the next tag, so the
    # cost stays linear on raw HTML with unclosed headings or many
    # unclosed <a starts. comrak escapes < in attribute values. A
    # hand-written class="anchor" link here is harmless to drop, as
    # filter_html would strip its class anyway.
    $html =~ s{
        <a\ href="\#[^"<>]*"\ [^<>]*\bclass="anchor"></a>
        (?=</h[1-6]>)
    }{}gx;

    return $html;
}

1;
