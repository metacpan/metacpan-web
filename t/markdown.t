use strict;
use warnings;
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

done_testing();
