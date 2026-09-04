use strict;
use warnings;
use lib 't/lib';

use Test::More;

use MetaCPAN::Web::RenderUtil qw( render_markdown );

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

like $html, qr{<h1>.*Heading.*</h1>}s,   'first heading';
like $html, qr{<h2>.*Heading.*</h2>}s,    'second heading';

# comrak generates anchor elements with id attributes inside headings
like $html, qr{id="heading"},              'first heading has id';
like $html, qr{id="heading-1"},            'duplicate heading gets -1 suffix';
like $html, qr{id="heading-2"},            'third duplicate gets -2 suffix';
like $html, qr{id="heading-with-markup"},  'heading with markup gets slugified id';

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

# GFM table rendering
$html = render_markdown(<<'EOM');
| Name | Value |
|------|-------|
| foo  | bar   |
| baz  | qux   |
EOM

like $html, qr{<table>},           'table rendered';
like $html, qr{<th>Name</th>},     'table header';
like $html, qr{<td>foo</td>},      'table cell';

# Strikethrough
$html = render_markdown("~~deleted~~\n");
like $html, qr{<del>deleted</del>}, 'strikethrough';

# Autolink
$html = render_markdown("Visit https://metacpan.org for more.\n");
like $html, qr{<a href="https://metacpan.org"}, 'autolink';

done_testing();
