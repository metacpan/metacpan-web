package MetaCPAN::Web::RenderUtil;

use strict;
use warnings;
use Sub::Exporter -setup => { exports => [qw(filter_html)], };

use HTML::Escape qw( escape_html );
use HTML::Restrict ();
use URI            ();

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
            tbody  => [],
            th     => [qw( colspan rowspan )],
            td     => [qw( colspan rowspan )],
            tr     => [],
            u      => [],
            ul     => [ { id => qr/^index$/ } ],

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
                        return '';
                    }
                    elsif ($data) {
                        my $base = "https://st.aticpan.org/source/";
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

1;
