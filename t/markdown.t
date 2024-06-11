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

like $html, qr{<h1 id="heading">Heading</h1>},   'first heading';
like $html, qr{<h2 id="heading-2">Heading</h2>}, 'second heading';
like $html, qr{<h2 id="heading-3">Heading</h2>}, 'third heading';

like $html, qr{<h2 id="heading-with-markup">Heading <}, 'heading with markup';

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

unlike $html, qr{Raw HTML}, 'raw html blocked';

eval { render_markdown( '# Heading', chorg => 1 ) };
like "$@", qr/^Unsupported options: chorg /, 'invalid options throw errors';

done_testing();
