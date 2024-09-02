package MetaCPAN::Web::RenderUtil;

use strict;
use warnings;
use Exporter qw(import);

use Carp           qw( croak );
use Digest::MD5    ();
use HTML::Escape   qw( escape_html );
use HTML::Restrict ();
use URI            ();
use CommonMark     qw(
    EVENT_ENTER
    EVENT_EXIT
    NODE_CODE
    NODE_CODE_BLOCK
    NODE_DOCUMENT
    NODE_HEADER
    NODE_HRULE
    NODE_HTML
    NODE_INLINE_HTML
    NODE_LINEBREAK
    NODE_SOFTBREAK
    NODE_TEXT
    OPT_UNSAFE
);

our @EXPORT_OK = qw(
    filter_html
    gravatar_image
    render_markdown
    split_index
);

sub filter_html {
    my ( $html, $data ) = @_;

    my $hr = HTML::Restrict->new(
        uri_schemes =>
            [ undef, 'http', 'https', 'data', 'mailto', 'irc', 'ircs' ],
        rules => {
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
    my $email
        = ( $author && $author->{pauseid} )
        ? $author->{pauseid} . '@cpan.org'
        : q{};
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

my @is_leaf;
$is_leaf[$_] = 1
    for (
    NODE_HTML,      NODE_HRULE,     NODE_CODE_BLOCK, NODE_TEXT,
    NODE_SOFTBREAK, NODE_LINEBREAK, NODE_CODE,       NODE_INLINE_HTML,
    );

sub render_markdown {
    my ( $markdown, %opts ) = @_;

    my $render_opts = 0;
    if ( delete $opts{unsafe} // 1 ) {
        $render_opts |= OPT_UNSAFE;
    }

    if (%opts) {
        croak "Unsupported options: " . join( ', ', sort keys %opts );
    }

    my $doc = CommonMark->parse_document($markdown);

    my ( $html, $header_content, %seen_header );

    my $iter = $doc->iterator;
    while ( my ( $ev_type, $node ) = $iter->next ) {
        my $node_type = $node->get_type;

        if ( $node_type == NODE_DOCUMENT ) {
            next;
        }

        if ( $node_type == NODE_HEADER ) {
            if ( $ev_type == EVENT_ENTER ) {
                $header_content = '';
            }
            if ( $ev_type == EVENT_EXIT ) {
                $header_content =~ s{(?:-(\d+))?$}{'-' . (($1 // 1) + 1)}e
                    while $seen_header{$header_content}++;

                my $header_html = $node->render_html($render_opts);
                $header_html
                    =~ s/^<h[0-9]+\b\K/' id="'.escape_html($header_content).'"'/e;
                $html .= $header_html;

                undef $header_content;
            }
        }
        elsif ($ev_type == EVENT_ENTER
            && $node->parent->get_type == NODE_DOCUMENT )
        {
            $html .= $node->render_html($render_opts);
        }

        if ( defined $header_content ) {
            if ( $is_leaf[$node_type] ) {
                my $content = lc( $node->get_literal );
                $content =~ s/\A\s+//;
                $content =~ s/\s+\z//;
                $content =~ s/\s+/-/g;

                if ( length $content ) {
                    $header_content .= '-' if length $header_content;
                    $header_content .= $content;
                }
            }
        }
    }

    return $html;
}

1;
