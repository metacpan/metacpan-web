use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestContext qw( get_context );

{
    # Test HTML is filtered after Markdown to HTML conversion
    my $file = {
        distribution => 'MetaCPAN::Web::View::HTML::Test',
        path         => '/t/view/html.t',
        author       => 'MCTESTFACE',
        release      => 'Test-0.00',
        sloc         => 0,
        slop         => 0,
        stat         => { size => 1 },
        binary       => 0,
    };

    my $c = get_context();

    my $markdown = <<~'MD';
        # A loaded blockquote
        > hello <a name="n"
        > href="javascript:alert('xss')">*you*</a>
        MD

    my $expected_md_as_html = <<~'MD_HTML';
            <h1 id="aloadedblockquote">A loaded blockquote</h1>


          <p>hello <a><em>you</em></a></p>
        MD_HTML

    $c->stash( {
        file                => $file,
        source              => $markdown,
        filetype            => 'markdown',
        suppress_stickeryou => 1,
    } );

    like(
        $c->view('HTML')->render( $c, 'source.html' ),
        qr/\Q$expected_md_as_html/,
        'HTML is filtered after Markdown rendering',
    );
}

done_testing();
