import SyntaxHighlighter, {
    registerBrush,
}
    from 'syntaxhighlighter';
import Renderer from 'syntaxhighlighter-html-renderer';

await Promise.all([
    import('./brush-cpan-changes.js').then(brush => registerBrush(brush)),
    import('brush-cpp').then(brush => registerBrush(brush)),
    import('brush-diff').then(brush => registerBrush(brush)),
    import('brush-javascript').then(brush => registerBrush(brush)),
    import('./brush-perl.js').then(brush => registerBrush(brush)),
    import('brush-plain').then(brush => registerBrush(brush)),
    import('brush-yaml').then(brush => registerBrush(brush)),
]);

const parseLines = (lines) => {
    lines = lines.split(/\s*,\s*/);
    var all_lines = [];
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        var res = line.match(/^\s*(\d+)\s*(?:-\s*(\d+)\s*)?$/);
        if (res) {
            var start = res[1] * 1;
            var end = (res[2] || res[1]) * 1;
            if (start > end) {
                var swap = end;
                end = start;
                start = swap;
            }
            for (var l = start; l <= end; l++) {
                all_lines.push(l);
            }
        }
    }
    return all_lines;
};

const findLines = (el, lines) => {
    const lineEls = [];
    for (const line of parseLines(lines)) {
        lineEls.push(...el.querySelectorAll(`:scope .syntaxhighlighter .line.number${line}`));
    }
    return lineEls;
};

const togglePod = (e) => {
    e.preventDefault();

    const scrollTop = window.scrollY;

    let topLine;
    let topOffset;
    for (const line of document.querySelectorAll('.syntaxhighlighter .container .line:not(.pod-line)')) {
        const lineTop = line.getBoundingClientRect().top;
        if (lineTop < 0) {
            topLine = line;
            topOffset = lineTop;
        }
        else {
            break;
        }
    }
    for (const toggle of document.querySelectorAll('.pod-toggle')) {
        toggle.classList.toggle('pod-hidden');
    }
    if (topLine) {
        const diff = topLine.getBoundingClientRect().top - topOffset;

        window.scrollTo({
            top:      scrollTop + diff,
            left:     0,
            behavior: 'instant',
        });
    }
};

const hashLines = /^#L(\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)$/;

// Original is /\w+:\/\/[\w-.\/?%&=:@;#]*/g
// Allow tilde, disallow period or percent as last character, and a more
// restricted scheme
SyntaxHighlighter.regexLib['url'] = /[a-z][a-z0-9.+-]*:\/\/[\w-./?%&=:@;#~]*[\w-/?&=:@;#~]/gi;

// Use regular spaces, not &nbsp;
SyntaxHighlighter.config.space = ' ';

// We aren't using <script type="syntaxhighlighter" />, and when enabled it
// attempts to strip <![CDATA[ ]]> sections. That code is buggy, and breaks
// short code blocks, such as on perlsecret.pod
SyntaxHighlighter.config.useScriptTags = false;

// https://metacpan.org/source/RWSTAUNER/Acme-Syntax-Examples-0.001/lib/Acme/Syntax/Examples.pm

// TODO: Might be easier to do the regexp on the plain string (before
// highlighting), gather up all the packages, then just linkify all
// references to the package name in the html after highlighting.

/**
 * Turns all package names into metacpan.org links within <a/> tags.
 * @param {String} code Input code.
 * @return {String} Returns code with </a> tags.
 */
const processPackages = function (code) {
    const target_pattern = this.opts.package_target_type == 'source' ? '/module/%s/source' : '/pod/%s';
    // This regexp is not great, but its good enough so far:
    // Match (possible) quotes or q operators followed by: an html entity or punctuation (not a letter).
    // Space should only be allowed after qw, but it probably doesn't hurt to match it.
    // This is a lax re for html entity, but probably good enough.
    const strip_delimiters = /((?:["']|q[qw]?(?:[^&a-z]|&#?[a-zA-Z0-9]+;))\s*)([A-Za-z0-9_:]+)(.*)/;

    // Wow, this regexp is hairy.
    // We have to specifically match the "qw" followed by a non-letter or an html entity followed by a closing tag,
    // because qw can have whitespace (newline) between the delimiter and the string(s).  Without this the delim is in $2
    // and the "</code>" at the end matches only the delim.
    // Without this the "qw" itself will be matched as the package.
    // Note that this will only match the first arg in a qw.. trying to match a second string
    // (again, possibly across a newline (which is  actually a new div))
    // without knowing where to end (the closing delimiter) would be really difficult.
    // See also the above comment about scanning the plain string and linkifying later.
    code = code.replace(/(<code class="p(?:er)?l keyword">(?:with|extends|use<\/code> <code class="p(?:er)?l plain">(?:parent|base|aliased|Mojo::Base))\s*<\/code>\s*<code class="p(?:er)?l string">(?:qw(?:[^&a-z]|&#?[a-zA-Z0-9]+;)<\/code>.+?<code class="p(?:er)?l string">)?)(.+?)(<\/code>)/g, function (m, prefix, pkg, suffix) {
        const match = strip_delimiters.exec(pkg);
        if (match) {
            prefix = prefix + match[1];
            pkg = match[2];
            suffix = match[3] + suffix;
        }

        const mcpan_url = target_pattern.replace(/%s/, pkg);
        const mcpan_link = '<a href="' + mcpan_url + '">' + pkg + '</a>';

        return prefix + mcpan_link + suffix;
    });

    const replace_pattern = '$1<a href="' + target_pattern.replace('%s', '$3') + '">$3</a>$4';
    // Link our dependencies
    return code.replace(/(<code class="p(?:er)?l keyword">(use|package|require)<\/code> <code class="p(?:er)?l plain">)([A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*)(.*?<\/code>)/g, replace_pattern);
};

const processUrls = Renderer.prototype.processUrls;
Renderer.prototype.processUrls = function (html, ...args) {
    html = processPackages.apply(this, [html]);
    html = processUrls.apply(this, [html, ...args]);
    return html;
};

const getHtml = Renderer.prototype.getHtml;
Renderer.prototype.getHtml = function (...args) {
    let html = getHtml.call(this, ...args);
    html = html.replace(/\s+(<(tbody|table|div)\b)/g, '$1');
    html = html.replace(/(<\/(tbody|table|div)>)\s+/g, '$1');
    return html;
};

const wrapLine = Renderer.prototype.wrapLine;
Renderer.prototype.wrapLine = function (lineIndex, lineNumber, lineHtml) {
    if (lineHtml == ' ') {
        lineHtml = '';
    }
    return wrapLine.call(this, lineIndex, lineNumber, lineHtml);
};

// on pod pages, set the language to perl if no other language is set
CODE: for (const code of document.querySelectorAll('.pod pre > code')) {
    for (const className of code.classList) {
        if (className.match(/(?:\s|^)language-\S+/)) {
            continue CODE;
        }
    }
    code.classList.add('language-perl');
}

const source = document.querySelector('#metacpan_source');
if (source) {
    const packageMatch = document.location.hash.match(/^#P(\S+)$/);
    const lineMatch = document.location.hash.match(hashLines);
    // avoid highlighting excessively large blocks of code as they will take
    // too long, causing browsers to lag and offer to kill the script
    if (source.innerHTML.length > 500000) {
        for (const el of source.querySelector('code')) {
            el.classList.remove(...el.classList);
        }
    }
    // check for 'P{encoded_package_name}' anchor, convert to
    // line number (if possible), and then highlight and jump
    // as long as the matching line is not the first line in
    // the code.
    else if (packageMatch) {
        const decodedPackageMatch = decodeURIComponent(packageMatch[1]);
        const leadingSource = source.innerText.split('package ' + decodedPackageMatch + ';');
        const lineCount = leadingSource[0].split('\n').length;
        if (leadingSource.length > 1 && lineCount > 1) {
            source.dataset.line = lineCount;
        }
        else if (window.history && window.history.replaceState) {
            // reset the anchor portion of the URL (it just looks neater).
            const loc = document.location.toString().replace(/#.*/, '');
            window.history.replaceState(null, '', loc);
        }
    }
    // save highlighted lines in an attribute, to be used later
    else if (lineMatch) {
        source.dataset.line = lineMatch[1];
    }
}

for (const code of document.querySelectorAll('main pre > code')) {
    const pre = code.parentNode;

    const config = {
        'gutter':     false,
        'toolbar':    false,
        'quick-code': false,
        'tab-size':   8,
    };
    for (const className of code.classList) {
        const res = className.match(/(?:\s|^)language-(\S+)/);
        if (res) {
            config.brush = res[1];
            break;
        }
    }

    if (!config.brush) {
        continue;
    }

    if (pre.classList.contains('line-numbers')) {
        config.gutter = true;
    }
    // starting line number can be provided by an attribute
    const first_line = pre.dataset.start;
    if (first_line) {
        config['first-line'] = first_line;
    }
    // highlighted lines can be provided by an attribute
    const lines = pre.dataset.line;
    if (lines) {
        config.highlight = parseLines(lines);
    }

    config.package_target_type = source ? 'source' : 'pod';

    let highlightObject = code;

    const html = code.innerHTML;
    if (html.match(/^ *\n+/)) {
        // highlighter strips leading blank lines, throwing off line numbers.
        // use this awful hack to bypass it. depends on specific details inside
        // the syntaxhighlighter module

        const fakeCode = {
            className: code.className,
            id:        code.id,
            title:     code.title,
            innerHTML: {
                toString: function () {
                    return html;
                },
                replace: function (search, replace) {
                    if (search.toString() == /^[ ]*[\n]+|[\n]*[ ]*$/g.toString()) {
                        return html.replace(/\n$/g, '');
                    }
                    return html.replace(search, replace);
                },
            },
        };
        const parentNode = code.parentNode;
        fakeCode.parentNode = {
            replaceChild: function (newEl, oldEl) {
                if (oldEl === fakeCode) {
                    oldEl = code;
                }
                parentNode.replaceChild(newEl, oldEl);
            },
        };

        highlightObject = fakeCode;
    }

    SyntaxHighlighter.highlight(config, highlightObject);

    const pod_lines = pre.dataset.podLines;
    if (pod_lines) {
        const lines = findLines(pre, pod_lines);
        let has_highlighted;
        for (const line of lines) {
            line.classList.add('pod-line');
            if (line.classList.contains('highlighted')) {
                has_highlighted = true;
            }
        }
        if (has_highlighted) {
            for (const toggle of document.querySelectorAll('.pod-toggle')) {
                toggle.classList.remove('pod-hidden');
            }
        }

        for (const line of lines) {
            const prev = line.previousSibling;
            if (!prev || !prev.classList.contains('pod-line')) {
                let gutter = line.closest('.gutter');
                const tmpl = document.createElement('template');
                if (gutter) {
                    tmpl.innerHTML = '<div class="pod-placeholder">&mdash;</div>';
                }
                else {
                    let lines = 1;
                    let next = line.nextSibling;
                    while (next && next.classList.contains('pod-line')) {
                        next = next.nextSibling;
                        lines++;
                    }
                    tmpl.innerHTML = '<div class="pod-placeholder"><button class="btn-link"><span class="hide-pod">Hide</span><span class="show-pod">Show</span> ' + lines + ' line' + (lines > 1 ? 's' : '') + ' of Pod</button></div>';
                }
                line.parentNode.insertBefore(tmpl.content, line);
                const toggleButton = line.previousSibling.querySelector('button');
                if (toggleButton) {
                    toggleButton.addEventListener('click', togglePod);
                }
            }
        }
    }
}

if (source) {
    // on the source page, make line numbers into links
    for (const line of source.querySelectorAll(':scope .syntaxhighlighter .gutter .line')) {
        const res = line.className.match(/(^|\s)number(\d+)(\s|$)/);
        if (!res)
            continue;
        const linenr = res[2];
        const id = 'L' + linenr;
        const link = document.createElement('a');
        link.href = '#' + id;
        link.id = id;
        link.append(...line.childNodes);
        line.append(link);
        link.addEventListener('click', (e) => {
            if (e.metaKey) {
                return false;
            }
            // normally the browser would update the url and scroll to
            // the the link.  instead, update the hash ourselves, but
            // unset the id first so it doesn't scroll
            e.preventDefault();

            let line = linenr;
            if (e.shiftKey && source.dataset.line) {
                const startLine = parseLines(source.dataset.line)[0];
                line = startLine < line ? startLine + '-' + line
                    : line + '-' + startLine;
            }
            link.removeAttribute('id');
            document.location.hash = '#L' + line;
            link.setAttribute('id', id);
            source.dataset.line = line;
        });
    }

    // if someone changes the url hash manually, update the highlighted lines
    window.addEventListener('hashchange', () => {
        const lineMatch = document.location.hash.match(hashLines);
        if (!lineMatch)
            return;
        source.dataset.line = lineMatch[1];
        for (const highlight of source.querySelectorAll(':scope .highlighted')) {
            highlight.classList.remove('highlighted');
        }
        let has_pod;
        const lines = findLines(source, lineMatch[1]);
        for (const highlight of lines) {
            highlight.classList.add('highlighted');
            if (highlight.classList.contains('pod-line')) {
                has_pod = true;
            }
        }
        if (has_pod) {
            for (const toggle of document.querySelectorAll('.pod-toggle')) {
                toggle.classList.remove('pod-hidden');
            }
        }
        lines[0].scrollIntoView({
            behavior: 'smooth',
        });
    });
}

// the line ids are added by javascript, so the browser won't have
// scrolled to it.  also, highlight ranges don't correspond to exact
// ids.  do the initial scroll ourselves.
const line_hash = document.location.hash.match(/^(#L\d+)(-|,|$)/);
if (line_hash) {
    const el = document.querySelector(line_hash[1]);
    if (el) {
        el.scrollIntoView({
            behavior: 'instant',
        });
    }
}

for (const toggle of document.querySelectorAll('button.pod-toggle')) {
    toggle.addEventListener('click', togglePod);
}
