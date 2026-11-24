use strict;
use warnings;
use lib 't/lib';

use HTML::TokeParser ();
use Test::More;
use Time::HiRes qw( time );

use MetaCPAN::Web::RenderUtil qw( filter_html render_markdown );

my $html = render_markdown(<<'EOM');
# Heading

Some body text

## Heading

More stuff

## Heading

more stuff

## Heading **with** _markup_

Content

EOM

like $html, qr{<h1[^>]*>.*Heading.*</h1>}s, 'first heading';
like $html, qr{<h2[^>]*>.*Heading.*</h2>}s, 'second heading';

# comrak's heading ids end up on the heading itself, not on an
# <a class="anchor"> inside it
like $html, qr{<h1 id="heading">},   'first heading has id';
like $html, qr{<h2 id="heading-1">}, 'duplicate heading gets -1 suffix';
like $html, qr{<h2 id="heading-2">}, 'third duplicate gets -2 suffix';
like $html, qr{<h2 id="heading-with-markup">},
    'heading with markup gets slugified id';
unlike $html, qr{class="anchor"}, 'no comrak anchor elements left';

$html = render_markdown(<<'EOM');
# Heading

Some body text

<div>Raw HTML</div>

EOM

like $html, qr{Raw HTML}, 'raw html allowed';

$html = render_markdown( <<'EOM', unsafe => 0 );
# Heading

Some body text

<div>Raw HTML</div>

EOM

unlike $html, qr{<div>.*Raw HTML}, 'raw html blocked';

eval { render_markdown( '# Heading', chorg => 1 ) };
like "$@", qr/^Unsupported options: chorg /, 'invalid options throw errors';

# comrak works on UTF-8 bytes; render_markdown takes and returns
# character strings, whether or not the input has the UTF-8 flag set
for my $case (
    [ 'latin-1 string',   "caf\x{e9}\n",          "caf\x{e9}" ],
    [ 'wide-char string', "caf\x{e9} \x{263a}\n", "caf\x{e9} \x{263a}" ],
    )
{
    my ( $label, $md, $text ) = @$case;
    is render_markdown($md), "<p>$text</p>\n", "non-ASCII round trip: $label";
}
is render_markdown(undef), q{}, 'undef input renders as empty string';
is render_markdown("a\0b\n"), "<p>a\x{FFFD}b</p>\n",
    'NUL is replaced rather than truncating the input';

# GFM table rendering
$html = render_markdown(<<'EOM');
| Name | Value |
|------|-------|
| foo  | bar   |
| baz  | qux   |
EOM

like $html, qr{<table>},       'table rendered';
like $html, qr{<th>Name</th>}, 'table header';
like $html, qr{<td>foo</td>},  'table cell';

# Strikethrough
$html = render_markdown("~~deleted~~\n");
like $html, qr{<del>deleted</del>}, 'strikethrough';

# Autolink
$html = render_markdown("Visit https://metacpan.org for more.\n");
like $html, qr{<a href="https://metacpan.org"}, 'autolink';

# Heading ids survive filter_html; createAnchors adds the bookmark
# link client-side
like filter_html( render_markdown("## Hello World\n") ),
    qr{<h2 id="hello-world">Hello World</h2>},
    'heading id survives filter_html';

# Anchor rewriting handles both comrak heading formats, so upgrading
# libcomrak_ffi past comrak 0.54 doesn't silently break heading anchors
{
    my $normalize = \&MetaCPAN::Web::RenderUtil::_normalize_heading_anchors;
    my %formats   = (
        'comrak < 0.54' =>
            '<h1><a href="#readme" aria-hidden="true" class="anchor" id="readme"></a>README</h1>',
        'comrak >= 0.54' =>
            q{<h1 id="readme">README<a href="#readme" aria-label="Link to heading 'README'" data-heading-content="README" class="anchor"></a></h1>},
    );
    for my $label ( sort keys %formats ) {
        is $normalize->( $formats{$label} ), '<h1 id="readme">README</h1>',
            "heading anchor normalized: $label";
    }

    is $normalize->(
        q{<h2 id="a-b">A <em>b</em><a href="#a-b" aria-label="Link to heading 'A b'" data-heading-content="A &lt;em&gt;b&lt;/em&gt;" class="anchor"></a></h2>}
        ),
        '<h2 id="a-b">A <em>b</em></h2>',
        'new format: heading with inline markup';

    is $normalize->(
        q{<h2 id="-1"><a href="#-1" aria-label="Link to heading ''" data-heading-content="" class="anchor"></a></h2>}
        ),
        '<h2 id="-1"></h2>',
        'new format: empty heading gets id -1';

    my $two
        = q{<h2 id="a">A<a href="#a" aria-label="x" data-heading-content="A" class="anchor"></a></h2>}
        . "\n<p>text</p>\n"
        . q{<h3 id="b">B<a href="#b" aria-label="x" data-heading-content="B" class="anchor"></a></h3>};
    is $normalize->($two),
        qq{<h2 id="a">A</h2>\n<p>text</p>\n<h3 id="b">B</h3>},
        'new format: each heading handled separately';

    # Raw HTML with many unclosed headings and a trailing anchor must
    # not take quadratic time
    my $unclosed
        = qq{<h2 id="a">x\n} x 20_000 . '<a href="#a" class="anchor"></a>';
    my $start = time;
    $normalize->($unclosed);
    cmp_ok time - $start, '<', 1, 'unclosed headings are not quadratic';

    my $many_starts
        = q{<a href="#" } x 20_000 . '<a href="#" class="anchor"></a>x';
    $start = time;
    $normalize->($many_starts);
    cmp_ok time - $start, '<', 1,
        'many unclosed anchor starts are not quadratic';

    my $user_link
        = '<h2 id="a">A <a href="https://example.com">link</a></h2>';
    is $normalize->($user_link), $user_link,
        'ordinary link at the end of a heading is left alone';
}

# comrak 0.56 removed tagfilter, so raw HTML reaches filter_html
# unescaped. Feed it raw tags, as comrak >= 0.56 emits them.
for my $tag (qw( script iframe style )) {
    my $html = filter_html("<p>Hi</p>\n<$tag>alert(1)</$tag>\n<p>ok</p>\n");
    unlike $html, qr/<$tag/i, "$tag tag stripped by filter_html";
    like $html,   qr/ok/,     "content after $tag kept";
}
unlike filter_html("<script>alert(1)</script>"), qr/alert/,
    'script content removed, not just the tags';

# Dangerous URL schemes are dropped from links and images. Without
# tagfilter, comrak with unsafe enabled passes these URLs through, so
# filter_html's uri_schemes and replace_img are the only check.
{
    # Scheme of each href/src as a browser would see it: entities
    # decoded, tab/newline removed anywhere, leading C0/space trimmed
    # (https://url.spec.whatwg.org/#concept-basic-url-parser)
    my $schemes = sub {
        my ($html) = @_;
        my $parser = HTML::TokeParser->new( \$html );
        my @found;
        while ( my $tag = $parser->get_tag ) {
            my $attrs = $tag->[1];
            next unless ref $attrs eq 'HASH';    # end tags
            for my $attr ( grep { exists $attrs->{$_} } qw( href src ) ) {

                # TokeParser has already decoded entities
                my $url = $attrs->{$attr};
                $url =~ s/[\t\n\r]//g;
                $url =~ s/^[\x00-\x20]+//;
                push @found, "$attr:"
                    . lc( $url =~ /^([a-z][a-z0-9+.-]*):/i ? $1 : '' );
            }
        }
        return join ',', @found;
    };
    my $bad_link = qr/\bhref:(?:javascript|vbscript|data)\b/;
    my $bad_img  = qr/\bsrc:(?:javascript|vbscript)\b/; # data: images allowed

    my @bad_urls = (
        'javascript:alert(1)',      'JavaScript:alert(1)',
        'jav&#x61;script:alert(1)', ' javascript:alert(1)',
        "java\tscript:alert(1)",    'java&#9;script:alert(1)',
        "java\nscript:alert(1)",    "\tjavascript:alert(1)",
        'vbscript:msgbox(1)',       'data:text/html,<b>x</b>',
    );
    for my $url (@bad_urls) {
        ( my $label = $url ) =~ s/\t/\\t/g;
        $label =~ s/\n/\\n/g;

        unlike $schemes->( filter_html(qq{<a href="$url">x</a>}) ),
            $bad_link, "raw link href neutralized: $label";
        unlike $schemes->( filter_html(qq{<img src="$url" alt="x">}) ),
            $bad_img, "raw img src neutralized: $label";
    }

    # The full render + filter pipeline, as root/md.tx runs it
    for my $md (
        '[x](javascript:alert(1))', '![x](javascript:alert(1))',
        '<javascript:alert(1)>',    '[x](JAVASCRIPT:alert(1))',
        '[x](vbscript:msgbox(1))',  '[x](jav&#x61;script:alert(1))',
        '![x](jav&#x61;script:alert(1))',
        )
    {
        my $found = $schemes->( filter_html( render_markdown("$md\n") ) );
        unlike $found, $bad_link, "markdown link neutralized: $md";
        unlike $found, $bad_img,  "markdown image neutralized: $md";
    }

    like filter_html( render_markdown("[ok](https://metacpan.org)\n") ),
        qr{href="https://metacpan.org"}, 'https link kept';
}

# filter_html strips class/aria-hidden from links, including values
# that mimic comrak's heading anchors
my %link_attrs = (
    'arbitrary values'       => 'class="evil" aria-hidden="sneaky"',
    'heading anchor mimic'   => 'class="anchor" aria-hidden="true"',
    'trailing newline mimic' => qq{class="anchor\n" aria-hidden="true\n"},
);
for my $label ( sort keys %link_attrs ) {
    my $filtered = filter_html(
        qq{<a href="http://example.com" $link_attrs{$label}>x</a>});
    unlike $filtered, qr/class=/,       "class stripped: $label";
    unlike $filtered, qr/aria-hidden=/, "aria-hidden stripped: $label";
    like $filtered,   qr/href="http:/,  "href retained: $label";
}

done_testing();
